part of ridemate_ai;

class AuthPage extends StatefulWidget {
  const AuthPage({required this.api, required this.onLoggedIn, super.key});
  final ApiClient api;
  final void Function(String, AppUser) onLoggedIn;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  bool isDriver = false;
  bool loading = false;
  String? error;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final vehicleTypeController = TextEditingController();
  final vehicleNumberController = TextEditingController();

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    
    try {
      Map<String, dynamic> res;
      if (isLogin) {
        res = await widget.api.post('/api/auth/login', {
          'email': emailController.text.trim(),
          'password': passwordController.text,
        });
      } else {
        res = await widget.api.post('/api/auth/signup', {
          'fullName': nameController.text.trim(),
          'mobileNumber': phoneController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text,
          'role': isDriver ? 'DRIVER' : 'RIDER',
          if (isDriver) 'vehicleType': vehicleTypeController.text.trim(),
          if (isDriver) 'vehicleNumber': vehicleNumberController.text.trim().toUpperCase(),
        });
      }
      widget.onLoggedIn(res['token'], AppUser.fromJson(res['user']));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.share_location_rounded, size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'RideMate AI',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.ink),
                ),
                Text(
                  isLogin ? 'Welcome back' : 'Create an account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 16, color: AppColors.muted),
                ),
                const SizedBox(height: 32),
                
                if (error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: Text(error!, style: const TextStyle(color: AppColors.danger)),
                  ),
                  
                SegmentedSwitch(
                  values: const ['login', 'signup'],
                  labels: const ['Login', 'Sign Up'],
                  selected: isLogin ? 'login' : 'signup',
                  onChanged: (idx) => setState(() => isLogin = idx == 0),
                ),
                const SizedBox(height: 24),
                
                if (!isLogin) ...[
                  AppField(label: 'Full Name', controller: nameController, icon: Icons.person_outline),
                  const SizedBox(height: 16),
                  AppField(label: 'Mobile Number', controller: phoneController, icon: Icons.phone_outlined),
                  const SizedBox(height: 16),
                  const Text('I want to join as a:', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SegmentedSwitch(
                    values: const ['rider', 'driver'],
                    labels: const ['Rider', 'Driver'],
                    selected: isDriver ? 'driver' : 'rider',
                    onChanged: (idx) => setState(() => isDriver = idx == 1),
                  ),
                  const SizedBox(height: 16),
                ],
                
                AppField(label: 'Email', controller: emailController, icon: Icons.email_outlined),
                const SizedBox(height: 16),
                AppField(label: 'Password', controller: passwordController, obscureText: true, icon: Icons.lock_outline),
                const SizedBox(height: 16),
                
                if (!isLogin && isDriver) ...[
                  AppField(label: 'Vehicle Type (e.g. Auto, Sedan)', controller: vehicleTypeController, icon: Icons.directions_car_outlined),
                  const SizedBox(height: 16),
                  AppField(label: 'Vehicle Number (e.g. MH12AB1234)', controller: vehicleNumberController, icon: Icons.numbers_outlined),
                  const SizedBox(height: 16),
                ],
                
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: loading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.bg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
                      : Text(isLogin ? 'Log In' : 'Sign Up', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


