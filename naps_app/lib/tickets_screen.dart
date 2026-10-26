import 'package:flutter/material.dart';
import 'app_models.dart';
import 'app_theme.dart';
import 'common_widgets.dart';

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({
    super.key,
    required this.tickets,
    required this.user,
    required this.createTicket,
    required this.updateTicket,
    required this.deleteTicket,
  });
  final List<SupportTicket> tickets;
  final AppUser user;
  final Future<void> Function(Map<String, dynamic>) createTicket;
  final Future<void> Function(String, Map<String, dynamic>) updateTicket;
  final Future<void> Function(String) deleteTicket;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      PageHeading(
        title: 'طلبات الدعم',
        subtitle: 'تابع طلبات فريقك وردود الجهات المختصة',
        action: IconButton(
          tooltip: 'طلب جديد',
          onPressed: () => createRequest(context),
          icon: const Icon(Icons.add),
        ),
      ),
      Expanded(
        child: tickets.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'لا توجد طلبات مسجلة. أرسل طلباً جديداً عند الحاجة.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: muted),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: tickets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  final isOwner = ticket.creatorId == user.id;
                  final isManager = user.role != 'employee';
                  return SurfacePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                ticket.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              _statusLabel(ticket.status),
                              style: TextStyle(
                                color: _statusColor(ticket.status),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (ticket.details.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Text(
                            ticket.details,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '${ticket.department}  ·  ${ticket.creatorName}  ·  ${arabicDate(ticket.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 4,
                          children: [
                            if (isManager && ticket.status == 'open')
                              TextButton(
                                onPressed: () => updateTicket(ticket.id, {
                                  'status': 'progress',
                                }),
                                child: const Text('بدء المعالجة'),
                              ),
                            if ((isManager && ticket.status == 'progress') ||
                                (isOwner && ticket.status != 'resolved'))
                              TextButton(
                                onPressed: () => updateTicket(ticket.id, {
                                  'status': 'resolved',
                                }),
                                child: const Text('إغلاق الطلب'),
                              ),
                            if (isManager || isOwner)
                              TextButton(
                                onPressed: () => confirmDelete(context, ticket),
                                child: const Text('حذف'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    ],
  );

  Future<void> createRequest(BuildContext context) async {
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _TicketFormDialog(),
    );
    if (values != null) await createTicket(values);
  }

  Future<void> confirmDelete(BuildContext context, SupportTicket ticket) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الطلب؟'),
        content: Text('سيتم حذف طلب «${ticket.title}» من سجل المؤسسة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) await deleteTicket(ticket.id);
  }

  String _statusLabel(String status) => switch (status) {
    'progress' => 'قيد المعالجة',
    'resolved' => 'مكتمل',
    _ => 'مفتوح',
  };
  Color _statusColor(String status) => switch (status) {
    'progress' => green,
    'resolved' => muted,
    _ => const Color(0xFF9A5A12),
  };
}

class _TicketFormDialog extends StatefulWidget {
  const _TicketFormDialog();

  @override
  State<_TicketFormDialog> createState() => _TicketFormDialogState();
}

class _TicketFormDialogState extends State<_TicketFormDialog> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final detailsController = TextEditingController();
  String department = 'الدعم التقني';

  @override
  void dispose() {
    titleController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('طلب دعم جديد'),
    content: Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'موضوع الطلب'),
              validator: (value) => value == null || value.trim().length < 3
                  ? 'اكتب موضوعاً واضحاً'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: detailsController,
              decoration: const InputDecoration(
                labelText: 'شرح المشكلة أو المطلوب',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: department,
              decoration: const InputDecoration(labelText: 'الجهة المختصة'),
              items:
                  const [
                        'الدعم التقني',
                        'خدمة العملاء',
                        'الموارد البشرية',
                        'الشؤون الإدارية',
                        'أخرى',
                      ]
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
              onChanged: (value) =>
                  setState(() => department = value ?? department),
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
            'details': detailsController.text.trim(),
            'department': department,
          });
        },
        child: const Text('إرسال'),
      ),
    ],
  );
}
