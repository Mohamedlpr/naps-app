import 'package:flutter/material.dart';
import 'app_models.dart';
import 'app_theme.dart';
import 'common_widgets.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({
    super.key,
    required this.tasks,
    required this.members,
    required this.user,
    required this.createTask,
    required this.updateTask,
    required this.deleteTask,
  });
  final List<WorkTask> tasks;
  final List<TeamMember> members;
  final AppUser user;
  final Future<void> Function(Map<String, dynamic>) createTask;
  final Future<void> Function(String, Map<String, dynamic>) updateTask;
  final Future<void> Function(String) deleteTask;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    final visibleTasks = widget.tasks
        .where(
          (task) =>
              filter == 'all' ||
              (filter == 'open' ? !task.complete : task.complete),
        )
        .toList();
    return Column(
      children: [
        PageHeading(
          title: 'المهام',
          subtitle: 'مسؤوليات مشتركة ومواعيد واضحة',
          action: IconButton(
            tooltip: 'مهمة جديدة',
            onPressed: () => editTask(),
            icon: const Icon(Icons.add),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('الكل')),
              ButtonSegment(value: 'open', label: Text('مفتوحة')),
              ButtonSegment(value: 'complete', label: Text('مكتملة')),
            ],
            selected: {filter},
            onSelectionChanged: (selected) =>
                setState(() => filter = selected.first),
          ),
        ),
        Expanded(
          child: visibleTasks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      filter == 'all'
                          ? 'لا توجد مهام بعد. أضف أول مهمة للفريق.'
                          : 'لا توجد مهام في هذا التصنيف.',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: muted),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: visibleTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = visibleTasks[index];
                    return SurfacePanel(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: task.complete,
                            onChanged: (value) => widget.updateTask(task.id, {
                              'status': value == true ? 'complete' : 'open',
                            }),
                            activeColor: green,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        decoration: task.complete
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: task.complete ? muted : ink,
                                      ),
                                ),
                                if (task.details.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    task.details,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                                const SizedBox(height: 9),
                                Text(
                                  'المسؤول: ${task.assigneeName}  ·  الفرع: ${task.branch}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  'الموعد: ${arabicDate(task.dueDate)}  ·  ${_statusLabel(task.status)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (task.status != 'complete')
                                  TextButton.icon(
                                    onPressed: () =>
                                        widget.updateTask(task.id, {
                                          'status': task.status == 'open'
                                              ? 'inProgress'
                                              : 'complete',
                                        }),
                                    icon: Icon(
                                      task.status == 'open'
                                          ? Icons.play_arrow_outlined
                                          : Icons.done,
                                    ),
                                    label: Text(
                                      task.status == 'open'
                                          ? 'بدء التنفيذ'
                                          : 'إتمام المهمة',
                                    ),
                                  ),
                                if (widget.user.role != 'employee')
                                  TextButton.icon(
                                    onPressed: () => editTask(task: task),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 17,
                                    ),
                                    label: const Text('تعديل'),
                                  ),
                              ],
                            ),
                          ),
                          if (widget.user.role != 'employee')
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') await editTask(task: task);
                                if (value == 'delete')
                                  await confirmDelete(task);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('تعديل المهمة'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('حذف المهمة'),
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
  }

  Future<void> editTask({WorkTask? task}) async {
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _TaskFormDialog(
        members: widget.members,
        user: widget.user,
        task: task,
      ),
    );
    if (values == null) return;
    if (task == null)
      await widget.createTask(values);
    else
      await widget.updateTask(task.id, values);
  }

  Future<void> confirmDelete(WorkTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المهمة؟'),
        content: Text('سيتم حذف «${task.title}» من مساحة عمل الفريق.'),
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
    if (confirmed == true) await widget.deleteTask(task.id);
  }

  String _statusLabel(String status) => switch (status) {
    'inProgress' => 'قيد التنفيذ',
    'complete' => 'مكتملة',
    _ => 'مفتوحة',
  };
}

class _TaskFormDialog extends StatefulWidget {
  const _TaskFormDialog({required this.members, required this.user, this.task});
  final List<TeamMember> members;
  final AppUser user;
  final WorkTask? task;

  @override
  State<_TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<_TaskFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final titleController = TextEditingController(
    text: widget.task?.title ?? '',
  );
  late final detailsController = TextEditingController(
    text: widget.task?.details ?? '',
  );
  late DateTime dueDate =
      widget.task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
  late String assigneeId = widget.task?.assigneeId ?? widget.user.id;

  @override
  void dispose() {
    titleController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.task == null ? 'مهمة جديدة' : 'تعديل المهمة'),
    content: Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'عنوان المهمة'),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'اكتب عنواناً واضحاً'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: detailsController,
              decoration: const InputDecoration(
                labelText: 'التفاصيل (اختياري)',
              ),
              maxLines: 3,
            ),
            if (widget.user.role != 'employee') ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue:
                    widget.members.any((member) => member.id == assigneeId)
                    ? assigneeId
                    : null,
                decoration: const InputDecoration(labelText: 'إسناد إلى'),
                items: widget.members
                    .map(
                      (member) => DropdownMenuItem(
                        value: member.id,
                        child: Text('${member.name} · ${member.branch}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => assigneeId = value ?? assigneeId),
              ),
            ],
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined, color: green),
              title: const Text('موعد الإنجاز'),
              subtitle: Text(arabicDate(dueDate)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: chooseDate,
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
        onPressed: save,
        child: Text(widget.task == null ? 'إضافة' : 'حفظ'),
      ),
    ],
  );

  Future<void> chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'اختر موعد الإنجاز',
    );
    if (selected != null) setState(() => dueDate = selected);
  }

  void save() {
    if (!formKey.currentState!.validate()) return;
    final values = <String, dynamic>{
      'title': titleController.text.trim(),
      'details': detailsController.text.trim(),
      'dueDate': dueDate.toIso8601String(),
    };
    if (widget.user.role == 'employee')
      values['assignedTo'] = widget.user.id;
    else
      values['assignedTo'] = assigneeId;
    Navigator.pop(context, values);
  }
}
