part of ridemate_ai;

class AuthPage extends StatefulWidget {
  const AuthPage({
    required this.api,
    required this.onLoggedIn,
    this.onDemoRequested,
    this.onAdminRequested,
    super.key,
  });

  final ApiClient api;
  final void Function(String token, AppUser user) onLoggedIn;
  final void Function(String role)? onDemoRequested;
  final VoidCallback? onAdminRequested;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final vehicleNumberController = TextEditingController();

  String role = 'RIDER';
  String mode = 'login';
  String vehicleType = 'Shared Auto';
  String message = '';
  bool loading = false;

  bool get isSignup => mode == 'signup';
  bool get isDriver => role == 'DRIVER';

  @override
  void dispose() {
    fullNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    passwordController.dispose();
    vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      loading = true;
      message = '';
    });

    try {
      final payload = <String, dynamic>{
        'role': role,
        'email': emailController.text.trim(),
        'password': passwordController.text,
      };

      if (isSignup) {
        payload.addAll({
          'fullName': fullNameController.text.trim(),
          'mobileNumber': mobileController.text.trim(),
        });
      }

      if (isSignup && isDriver) {
        payload.addAll({
          'vehicleType': vehicleType,
          'vehicleNumber': vehicleNumberController.text.trim(),
        });
      }

      final endpoint = isSignup ? '/api/auth/signup' : '/api/auth/login';
      final data = await widget.api.post(endpoint, payload);
      widget.onLoggedIn(
        data['token'].toString(),
        AppUser.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on ApiException catch (error) {
      setState(() => message = error.message);
    } catch (_) {
      setState(() => message = 'Could not connect to backend server.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.bg, AppColors.bgAlt],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final hero = AuthHeroPanel(compact: !wide);
              final form = AuthFormPanel(
                formKey: formKey,
                role: role,
                mode: mode,
                isSignup: isSignup,
                isDriver: isDriver,
                vehicleType: vehicleType,
                message: message,
                loading: loading,
                fullNameController: fullNameController,
                mobileController: mobileController,
                emailController: emailController,
                passwordController: passwordController,
                vehicleNumberController: vehicleNumberController,
                onRoleChanged: (value) => setState(() {
                  role = value;
                  message = '';
                }),
                onModeChanged: (value) => setState(() {
                  mode = value;
                  message = '';
                }),
                onVehicleTypeChanged: (value) =>
                    setState(() => vehicleType = value),
                onSubmit: submit,
                onDemoRequested: widget.onDemoRequested,
                onAdminRequested: widget.onAdminRequested,
              );

              if (wide) {
                return Row(
                  children: [
                    Expanded(
                      flex: 11,
                      child: Padding(
                          padding: const EdgeInsets.all(24), child: hero),
                    ),
                    Expanded(
                      flex: 9,
                      child: Padding(
                          padding: const EdgeInsets.all(24), child: form),
                    ),
                  ],
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
                children: [
                  hero,
                  const SizedBox(height: 18),
                  form,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
