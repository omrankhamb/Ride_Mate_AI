part of ridemate_ai;

class AuthFormPanel extends StatelessWidget {
  const AuthFormPanel({
    required this.formKey,
    required this.role,
    required this.mode,
    required this.isSignup,
    required this.isDriver,
    required this.vehicleType,
    required this.message,
    required this.loading,
    required this.fullNameController,
    required this.mobileController,
    required this.emailController,
    required this.passwordController,
    required this.vehicleNumberController,
    required this.onRoleChanged,
    required this.onModeChanged,
    required this.onVehicleTypeChanged,
    required this.onSubmit,
    this.onDemoRequested,
    this.onAdminRequested,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final String role;
  final String mode;
  final bool isSignup;
  final bool isDriver;
  final String vehicleType;
  final String message;
  final bool loading;
  final TextEditingController fullNameController;
  final TextEditingController mobileController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController vehicleNumberController;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<String> onVehicleTypeChanged;
  final VoidCallback onSubmit;
  final void Function(String role)? onDemoRequested;
  final VoidCallback? onAdminRequested;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 600),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 28, offset: Offset(0, 18)),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedSwitch(
                    values: const ['RIDER', 'DRIVER'],
                    labels: const ['Rider', 'Driver'],
                    selected: role,
                    onChanged: onRoleChanged,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isSignup ? 'Create account' : 'Welcome back',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isDriver
                        ? 'Sign in as a driver and go online.'
                        : 'Sign in as a rider and book a shared ride.',
                    style:
                        const TextStyle(color: AppColors.muted, height: 1.45),
                  ),
                  const SizedBox(height: 18),
                  SegmentedSwitch(
                    values: const ['login', 'signup'],
                    labels: const ['Login', 'Sign up'],
                    selected: mode,
                    onChanged: onModeChanged,
                  ),
                  const SizedBox(height: 18),
                  if (isSignup) ...[
                    AppField(
                      controller: fullNameController,
                      label: 'Full name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    AppField(
                      controller: mobileController,
                      label: 'Mobile number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                  ],
                  AppField(
                    controller: emailController,
                    label: 'Email',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  AppField(
                    controller: passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    minLength: 6,
                  ),
                  if (isSignup && isDriver) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: vehicleType,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle type',
                        prefixIcon: Icon(Icons.local_taxi_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Shared Auto', child: Text('Shared Auto')),
                        DropdownMenuItem(
                            value: 'E-Rickshaw', child: Text('E-Rickshaw')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          onVehicleTypeChanged(value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    AppField(
                      controller: vehicleNumberController,
                      label: 'Vehicle number',
                      icon: Icons.confirmation_number_outlined,
                      hint: 'MH12AB1234',
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: loading ? null : onSubmit,
                    child: Text(loading
                        ? 'Please wait...'
                        : isSignup
                            ? 'Create account'
                            : 'Login'),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: message.isEmpty
                        ? const SizedBox(height: 18)
                        : Text(
                            message,
                            key: ValueKey(message),
                            style: const TextStyle(color: AppColors.danger),
                          ),
                  ),
                  if (onDemoRequested != null) ...[
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => onDemoRequested!(role),
                          child: Text(
                            'Quick Demo Login ($role)',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ),
                        if (onAdminRequested != null) ...[
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: onAdminRequested,
                            child: const Text(
                              'Admin Dashboard',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
