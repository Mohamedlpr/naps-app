import 'package:flutter/material.dart';
import 'app_models.dart';
import 'app_theme.dart';
import 'common_widgets.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({
    super.key,
    required this.members,
    required this.user,
    required this.createUser,
    required this.updateUser,
    required this.changePassword,
    required this.onLogout,
  });
  final List<TeamMember> members;
  final AppUser user;
  final Future<void> Function(Map<String, dynamic>) createUser;
  final Future<void> Function(String, Map<String, dynamic>) updateUser;
  final Future<void> Function(String, String) changePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.zero,
    children: [
      PageHeading(
        title: 'الفريق والحساب',
        subtitle: 'إدارة أعضاء مساحة العمل وصلاحياتهم',
        action: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'password') updatePassword(context);
            if (value == 'logout') onLogout();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'password', child: Text('تغيير كلمة المرور')),
            PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        child: SurfacePanel(
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE7F0E9),
                child: Text(
                  user.name.isEmpty ? '؟' : user.name.substring(0, 1),
                  style: const TextStyle(
                    color: green,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${_roleLabel(user.role)}  ·  ${user.branch}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Row(
          children: [
            Expanded(child: SectionTitle('أعضاء المؤسسة · ${members.length}')),
            if (user.role != 'employee')
              IconButton(
                tooltip: 'إضافة عضو',
                onPressed: () => create(context),
                icon: const Icon(Icons.person_add_alt_1),
              ),
          ],
        ),
      ),
      if (members.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SurfacePanel(
            child: Text('لا يوجد أعضاء نشطون في مساحة العمل.'),
          ),
        )
      else
        ...members.map(
          (member) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: SurfacePanel(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: const Color(0xFFE7F0E9),
                    child: Text(
                      member.name.isEmpty ? '؟' : member.name.substring(0, 1),
                      style: const TextStyle(
                        color: green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${_roleLabel(member.role)}  ·  ${member.branch}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          member.email,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (member.phone.isNotEmpty)
                          Text(
                            member.phone,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (user.role == 'admin' && member.role != 'admin')
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'supervisor' || value == 'employee')
                          updateUser(member.id, {'role': value});
                        if (value == 'deactivate')
                          updateUser(member.id, {'active': false});
                      },
                      itemBuilder: (_) => [
                        if (member.role != 'supervisor')
                          const PopupMenuItem(
                            value: 'supervisor',
                            child: Text('ترقية إلى مشرف'),
                          ),
                        if (member.role != 'employee')
                          const PopupMenuItem(
                            value: 'employee',
                            child: Text('تعيين كموظف'),
                          ),
                        const PopupMenuItem(
                          value: 'deactivate',
                          child: Text('إيقاف الحساب'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Text(
          'إيقاف الحساب يمنع تسجيل الدخول ويُبقي السجلات السابقة محفوظة.',
          style: TextStyle(color: muted, fontSize: 12, height: 1.6),
        ),
      ),
    ],
  );

  Future<void> create(BuildContext context) async {
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          _MemberFormDialog(canCreateAdmin: user.role == 'admin'),
    );
    if (values != null) await createUser(values);
  }

  Future<void> updatePassword(BuildContext context) async {
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _PasswordFormDialog(),
    );
    if (values != null)
      await changePassword(values['currentPassword']!, values['newPassword']!);
  }

  String _roleLabel(String role) => switch (role) {
    'admin' => 'مسؤول المؤسسة',
    'supervisor' => 'مشرف',
    _ => 'موظف',
  };
}

class _MemberFormDialog extends StatefulWidget {
  const _MemberFormDialog({required this.canCreateAdmin});
  final bool canCreateAdmin;

  @override
  State<_MemberFormDialog> createState() => _MemberFormDialogState();
}

class _PasswordFormDialog extends StatefulWidget {
  const _PasswordFormDialog();

  @override
  State<_PasswordFormDialog> createState() => _PasswordFormDialogState();
}

class _PasswordFormDialogState extends State<_PasswordFormDialog> {
  final formKey = GlobalKey<FormState>();
  final currentController = TextEditingController();
  final newController = TextEditingController();

  @override
  void dispose() {
    currentController.dispose();
    newController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('تغيير كلمة المرور'),
    content: Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: currentController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'كلمة المرور الحالية'),
            validator: _required,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: newController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'كلمة المرور الجديدة (١٢ حرفاً على الأقل)',
            ),
            validator: (value) => value == null || value.length < 12
                ? 'استخدم ١٢ حرفاً على الأقل'
                : null,
          ),
        ],
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
            'currentPassword': currentController.text,
            'newPassword': newController.text,
          });
        },
        child: const Text('حفظ'),
      ),
    ],
  );

  String? _required(String? value) =>
      value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null;
}

class _MemberFormDialogState extends State<_MemberFormDialog> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final branchController = TextEditingController();
  final phoneController = TextEditingController();
  String role = 'employee';

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    branchController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('إضافة عضو للفريق'),
    content: Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(nameController, 'الاسم', validator: _required),
            const SizedBox(height: 9),
            _field(
              emailController,
              'البريد الإلكتروني',
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              validator: _emailValidator,
            ),
            const SizedBox(height: 9),
            _field(
              passwordController,
              'كلمة مرور مؤقتة (١٢ حرفاً على الأقل)',
              obscureText: true,
              textDirection: TextDirection.ltr,
              validator: (value) => value == null || value.length < 12
                  ? 'استخدم ١٢ حرفاً على الأقل'
                  : null,
            ),
            const SizedBox(height: 9),
            _field(branchController, 'الفرع', validator: _required),
            const SizedBox(height: 9),
            _field(
              phoneController,
              'رقم التواصل (اختياري)',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 9),
            DropdownButtonFormField<String>(
              initialValue: role,
              decoration: const InputDecoration(labelText: 'الصلاحية'),
              items: [
                const DropdownMenuItem(value: 'employee', child: Text('موظف')),
                const DropdownMenuItem(
                  value: 'supervisor',
                  child: Text('مشرف'),
                ),
                if (widget.canCreateAdmin)
                  const DropdownMenuItem(
                    value: 'admin',
                    child: Text('مسؤول مؤسسة'),
                  ),
              ],
              onChanged: (value) => setState(() => role = value ?? role),
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
      FilledButton(onPressed: save, child: const Text('إنشاء الحساب')),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextDirection textDirection = TextDirection.rtl,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    keyboardType: keyboardType,
    obscureText: obscureText,
    validator: validator,
    autocorrect: false,
    textDirection: textDirection,
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null;

  String? _emailValidator(String? value) =>
      value == null ||
          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
      ? 'أدخل بريداً إلكترونياً صحيحاً'
      : null;

  void save() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'password': passwordController.text,
      'branch': branchController.text.trim(),
      'phone': phoneController.text.trim(),
      'role': role,
    });
  }
}
