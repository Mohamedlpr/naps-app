import 'package:flutter/material.dart';
import 'api_client.dart';
import 'app_models.dart';
import 'app_theme.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({
    super.key,
    required this.apiClient,
    required this.onAuthenticated,
    this.initialError,
  });
  final ApiClient apiClient;
  final ValueChanged<AppUser> onAuthenticated;
  final String? initialError;

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final organizationController = TextEditingController();
  final branchController = TextEditingController();
  final setupSecretController = TextEditingController();
  bool isSetup = false;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    errorMessage = widget.initialError;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    organizationController.dispose();
    branchController.dispose();
    setupSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: green),
                      child: const Text(
                        'ن',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إدارة العمل',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                        Text(
                          'مساحة مشتركة لفريقك',
                          style: TextStyle(fontSize: 13, color: muted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'إعداد الاتصال',
                      onPressed: configureServer,
                      icon: const Icon(Icons.tune),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Text(
                  isSetup ? 'تهيئة المؤسسة' : 'تسجيل الدخول',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 7),
                Text(
                  isSetup
                      ? 'أنشئ حساب المسؤول الأول لبدء استخدام مساحة العمل.'
                      : 'سجّل الدخول للوصول إلى مهام فريقك وطلباته.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: muted),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 18),
                  _MessageBox(message: errorMessage!, isError: true),
                ],
                const SizedBox(height: 22),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      if (isSetup) ...[
                        _field(
                          organizationController,
                          'اسم المؤسسة',
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          nameController,
                          'اسم المسؤول الأول',
                          validator: _required,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _field(
                        emailController,
                        'البريد الإلكتروني',
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        validator: _emailValidator,
                      ),
                      if (isSetup) ...[
                        const SizedBox(height: 12),
                        _field(
                          branchController,
                          'الفرع أو موقع العمل',
                          validator: _required,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _field(
                        passwordController,
                        isSetup
                            ? 'كلمة مرور جديدة (١٢ حرفاً على الأقل)'
                            : 'كلمة المرور',
                        obscureText: true,
                        textDirection: TextDirection.ltr,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'أدخل كلمة المرور';
                          if (isSetup && value.length < 12)
                            return 'استخدم ١٢ حرفاً على الأقل';
                          return null;
                        },
                      ),
                      if (isSetup) ...[
                        const SizedBox(height: 12),
                        _field(
                          setupSecretController,
                          'رمز التهيئة من مسؤول الخادم',
                          obscureText: true,
                          validator: _required,
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: isLoading ? null : submit,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(isSetup ? 'إنشاء مساحة العمل' : 'دخول'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () => setState(() {
                            isSetup = !isSetup;
                            errorMessage = null;
                          }),
                    child: Text(
                      isSetup ? 'لديك حساب؟ سجّل الدخول' : 'إعداد مؤسسة جديدة',
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const _MessageBox(
                  message:
                      'يلزم تشغيل خادم المؤسسة للاتصال بين الأجهزة. بيانات العمل تُحفظ في قاعدة بيانات الخادم.',
                  isError: false,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
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
    textDirection: textDirection,
    autocorrect: false,
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null;

  String? _emailValidator(String? value) {
    if (value == null ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim()))
      return 'أدخل بريداً إلكترونياً صحيحاً';
    return null;
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final user = isSetup
          ? await widget.apiClient.bootstrapOrganization({
              'setupSecret': setupSecretController.text,
              'organizationName': organizationController.text.trim(),
              'name': nameController.text.trim(),
              'email': emailController.text.trim(),
              'password': passwordController.text,
              'branch': branchController.text.trim(),
            })
          : await widget.apiClient.login(
              emailController.text,
              passwordController.text,
            );
      widget.onAuthenticated(user);
    } on ApiException catch (error) {
      if (mounted) setState(() => errorMessage = error.message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> configureServer() async {
    final serverUrl = await showDialog<String>(
      context: context,
      builder: (context) =>
          _ServerAddressDialog(initialUrl: widget.apiClient.baseUrl),
    );
    if (serverUrl != null) {
      try {
        await widget.apiClient.setBaseUrl(serverUrl);
        if (mounted) setState(() => errorMessage = null);
      } on ApiException catch (error) {
        if (mounted) setState(() => errorMessage = error.message);
      }
    }
  }
}

class _ServerAddressDialog extends StatefulWidget {
  const _ServerAddressDialog({required this.initialUrl});
  final String initialUrl;

  @override
  State<_ServerAddressDialog> createState() => _ServerAddressDialogState();
}

class _ServerAddressDialogState extends State<_ServerAddressDialog> {
  late final controller = TextEditingController(text: widget.initialUrl);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('عنوان الخادم'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('أدخل عنوان واجهة API التي ستتصل بها أجهزة الفريق.'),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://api.example.com/api',
          ),
          textDirection: TextDirection.ltr,
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('إلغاء'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, controller.text.trim()),
        child: const Text('حفظ'),
      ),
    ],
  );
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message, required this.isError});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: isError ? const Color(0xFFFFF2EC) : const Color(0xFFEAF1EA),
      border: Border.all(
        color: isError ? const Color(0xFFE8B6A1) : const Color(0xFFCBDCCB),
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      message,
      style: TextStyle(
        color: isError ? const Color(0xFF8B3922) : green,
        height: 1.6,
        fontSize: 13,
      ),
    ),
  );
}
