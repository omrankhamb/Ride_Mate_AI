import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const RideMateApp());
}

class RideMateApp extends StatelessWidget {
  const RideMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RideMate AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.green,
          primary: AppColors.green,
          secondary: AppColors.yellow,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.soft,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.green, width: 1.6),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: AppColors.greenDark,
            side: const BorderSide(color: AppColors.line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      home: const AppRoot(),
    );
  }
}

class AppColors {
  static const green = Color(0xFF0F7A4A);
  static const greenDark = Color(0xFF0F5132);
  static const yellow = Color(0xFFF8C146);
  static const ink = Color(0xFF152028);
  static const muted = Color(0xFF5C6872);
  static const line = Color(0xFFDCE3E8);
  static const soft = Color(0xFFF5F7F8);
  static const sky = Color(0xFFD8EEF2);
  static const danger = Color(0xFFB3261E);
}

class ApiClient {
  ApiClient({this.baseUrl = 'http://localhost:3000'});

  final String baseUrl;
  String? token;

  Future<Map<String, dynamic>> get(String path) {
    return _send('GET', path);
  }

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) {
    return _send('POST', path, body);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    late http.Response response;
    if (method == 'POST') {
      response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body ?? {}),
      );
    } else {
      response = await http.get(uri, headers: headers);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(decoded['message']?.toString() ?? 'Request failed');
    }
    return decoded;
  }
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppUser {
  AppUser({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    required this.email,
    required this.role,
  });

  final String id;
  final String fullName;
  final String mobileNumber;
  final String email;
  final String role;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      fullName: json['fullName'].toString(),
      mobileNumber: json['mobileNumber'].toString(),
      email: json['email'].toString(),
      role: json['role'].toString(),
    );
  }
}

class Ride {
  Ride({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.status,
    required this.otp,
    required this.coRiderPickupDistanceMeters,
    required this.estimatedFare,
    this.etaMinutes,
    this.rider,
    this.driver,
    this.driverProfile,
  });

  final String id;
  final String pickup;
  final String destination;
  final String status;
  final String otp;
  final int coRiderPickupDistanceMeters;
  final int estimatedFare;
  final int? etaMinutes;
  final AppUser? rider;
  final AppUser? driver;
  final Map<String, dynamic>? driverProfile;

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'].toString(),
      pickup: json['pickup'].toString(),
      destination: json['destination'].toString(),
      status: json['status'].toString(),
      otp: json['otp'].toString(),
      coRiderPickupDistanceMeters: int.tryParse(
            json['coRiderPickupDistanceMeters'].toString(),
          ) ??
          0,
      estimatedFare: int.tryParse(json['estimatedFare'].toString()) ?? 0,
      etaMinutes: json['etaMinutes'] == null
          ? null
          : int.tryParse(json['etaMinutes'].toString()),
      rider: json['rider'] == null
          ? null
          : AppUser.fromJson(json['rider'] as Map<String, dynamic>),
      driver: json['driver'] == null
          ? null
          : AppUser.fromJson(json['driver'] as Map<String, dynamic>),
      driverProfile: json['driverProfile'] == null
          ? null
          : Map<String, dynamic>.from(json['driverProfile'] as Map),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final api = ApiClient();
  AppUser? user;

  void handleLoggedIn(String token, AppUser nextUser) {
    setState(() {
      api.token = token;
      user = nextUser;
    });
  }

  void handleLogout() {
    setState(() {
      api.token = null;
      user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return AuthScreen(api: api, onLoggedIn: handleLoggedIn);
    }

    if (user!.role == 'DRIVER') {
      return DriverDashboard(api: api, user: user!, onLogout: handleLogout);
    }

    return RiderDashboard(api: api, user: user!, onLogout: handleLogout);
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.api,
    required this.onLoggedIn,
    super.key,
  });

  final ApiClient api;
  final void Function(String token, AppUser user) onLoggedIn;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
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
      final response = await widget.api.post(endpoint, payload);
      final loggedInUser = AppUser.fromJson(
        response['user'] as Map<String, dynamic>,
      );
      widget.onLoggedIn(response['token'].toString(), loggedInUser);
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 860;
            final brand = BrandPanel(compact: !isWide);
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
              onVehicleTypeChanged: (value) {
                setState(() => vehicleType = value);
              },
              onSubmit: submit,
            );

            if (isWide) {
              return Row(
                children: [
                  Expanded(flex: 9, child: brand),
                  Expanded(flex: 11, child: form),
                ],
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 320, child: brand),
                  form,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class BrandPanel extends StatelessWidget {
  const BrandPanel({required this.compact, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 24 : 42),
      decoration: const BoxDecoration(color: AppColors.greenDark),
      child: CustomPaint(
        painter: GridPainter(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandLogo(light: true),
                SizedBox(height: compact ? 34 : 58),
                Text(
                  'Shared auto rides with rider and driver flows.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 30 : 42,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sign up, login, request a shared auto, show co-rider pickup distance, and let drivers accept rides in one MVP.',
                  style: TextStyle(
                    color: Color(0xFFDCEDE5),
                    fontSize: 16,
                    height: 1.55,
                  ),
                ),
              ],
            ),
            const Text(
              'Phase 1: no KYC, no admin, no payment gateway.',
              style: TextStyle(color: Color(0xFFDCEDE5)),
            ),
          ],
        ),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedControl(
                values: const ['RIDER', 'DRIVER'],
                labels: const ['Rider', 'Driver'],
                selected: role,
                onChanged: onRoleChanged,
              ),
              const SizedBox(height: 28),
              Text(
                '${isSignup ? 'Create' : 'Login'} ${role == 'DRIVER' ? 'Driver' : 'Rider'} Account',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                role == 'DRIVER'
                    ? 'Go online and receive shared auto requests.'
                    : 'Request a shared auto and see ride status.',
                style: const TextStyle(color: AppColors.muted, height: 1.45),
              ),
              const SizedBox(height: 22),
              SegmentedControl(
                values: const ['login', 'signup'],
                labels: const ['Login', 'Sign Up'],
                selected: mode,
                onChanged: onModeChanged,
              ),
              const SizedBox(height: 20),
              if (isSignup) ...[
                AppTextField(
                  controller: fullNameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: mobileController,
                  label: 'Mobile Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
              ],
              AppTextField(
                controller: emailController,
                label: 'Email',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                obscureText: true,
                minLength: 6,
              ),
              if (isSignup && isDriver) ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: vehicleType,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Type',
                    prefixIcon: Icon(Icons.local_taxi_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Shared Auto',
                      child: Text('Shared Auto'),
                    ),
                    DropdownMenuItem(
                      value: 'E-Rickshaw',
                      child: Text('E-Rickshaw'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onVehicleTypeChanged(value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: vehicleNumberController,
                  label: 'Vehicle Number',
                  icon: Icons.confirmation_number_outlined,
                  hint: 'MH12AB1234',
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loading ? null : onSubmit,
                child: Text(
                  loading
                      ? 'Please wait...'
                      : isSignup
                          ? 'Create Account'
                          : 'Login',
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: message.isEmpty
                    ? const SizedBox(height: 22)
                    : Text(
                        message,
                        key: ValueKey(message),
                        style: const TextStyle(color: AppColors.danger),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.minLength,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? minLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) {
          return '$label is required';
        }
        if (minLength != null && text.length < minLength!) {
          return '$label must be at least $minLength characters';
        }
        return null;
      },
    );
  }
}

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({
    required this.api,
    required this.user,
    required this.onLogout,
    super.key,
  });

  final ApiClient api;
  final AppUser user;
  final VoidCallback onLogout;

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  final pickupController = TextEditingController();
  final destinationController = TextEditingController();

  Ride? ride;
  bool loading = false;
  String message = '';

  @override
  void initState() {
    super.initState();
    loadLatestRide();
  }

  @override
  void dispose() {
    pickupController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  Future<void> loadLatestRide() async {
    try {
      final response = await widget.api.get('/api/rides/mine');
      final rides = (response['rides'] as List)
          .map((item) => Ride.fromJson(item as Map<String, dynamic>))
          .toList();
      Ride? selectedRide;
      for (final item in rides) {
        if (item.status != 'COMPLETED' && item.status != 'CANCELLED') {
          selectedRide = item;
          break;
        }
      }
      selectedRide ??= rides.isEmpty ? null : rides.first;
      setState(() => ride = selectedRide);
    } catch (_) {
      setState(() => ride = null);
    }
  }

  Future<void> requestRide() async {
    if (pickupController.text.trim().isEmpty ||
        destinationController.text.trim().isEmpty) {
      setState(() => message = 'Pickup and destination are required.');
      return;
    }

    setState(() {
      loading = true;
      message = '';
    });

    try {
      final response = await widget.api.post('/api/rides/request', {
        'pickup': pickupController.text.trim(),
        'destination': destinationController.text.trim(),
      });
      setState(() {
        ride = Ride.fromJson(response['ride'] as Map<String, dynamic>);
      });
    } on ApiException catch (error) {
      setState(() => message = error.message);
    } catch (_) {
      setState(() => message = 'Could not request ride.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapShell(
      user: widget.user,
      subtitle: 'Rider dashboard',
      onLogout: widget.onLogout,
      bottomSheet: RidePanel(
        title: 'Request Shared Auto',
        subtitle: 'Choose pickup and endpoint. Co-rider pickup distance appears after matching.',
        status: ride?.status ?? 'READY',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final stackFields = constraints.maxWidth < 560;
                final pickup = AppTextField(
                  controller: pickupController,
                  label: 'Pickup Location',
                  icon: Icons.my_location_outlined,
                  hint: 'College gate',
                );
                final destination = AppTextField(
                  controller: destinationController,
                  label: 'Destination Endpoint',
                  icon: Icons.flag_outlined,
                  hint: 'Railway station',
                );

                if (stackFields) {
                  return Column(
                    children: [
                      pickup,
                      const SizedBox(height: 12),
                      destination,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: pickup),
                    const SizedBox(width: 12),
                    Expanded(child: destination),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: loading ? null : requestRide,
              icon: const Icon(Icons.search),
              label: Text(loading ? 'Finding driver...' : 'Find Shared Auto'),
            ),
            const SizedBox(height: 16),
            if (ride == null)
              const EmptyCard(text: 'No active ride yet.')
            else
              RiderRideCard(ride: ride!),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(message, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
    );
  }
}

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({
    required this.api,
    required this.user,
    required this.onLogout,
    super.key,
  });

  final ApiClient api;
  final AppUser user;
  final VoidCallback onLogout;

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final otpController = TextEditingController();

  bool online = false;
  bool loading = false;
  String message = '';
  List<Ride> rides = [];

  @override
  void initState() {
    super.initState();
    loadRides();
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  Future<void> updateStatus(bool isOnline) async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      await widget.api.post('/api/drivers/status', {
        'isOnline': isOnline,
        'locationLabel': 'Driver near demo pickup',
        'lat': 18.5204,
        'lng': 73.8567,
      });
      setState(() => online = isOnline);
      await loadRides();
    } on ApiException catch (error) {
      setState(() => message = error.message);
    } catch (_) {
      setState(() => message = 'Could not update driver status.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> loadRides() async {
    try {
      final response = await widget.api.get('/api/drivers/rides');
      setState(() {
        rides = (response['rides'] as List)
            .map((item) => Ride.fromJson(item as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      setState(() => rides = []);
    }
  }

  Future<void> rideAction(Ride ride, String action) async {
    setState(() => message = '');

    try {
      await widget.api.post('/api/rides/${ride.id}/$action', {
        if (action == 'start') 'otp': otpController.text.trim(),
      });
      otpController.clear();
      await loadRides();
    } on ApiException catch (error) {
      setState(() => message = error.message);
    } catch (_) {
      setState(() => message = 'Could not update ride.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapShell(
      user: widget.user,
      subtitle: 'Driver dashboard',
      onLogout: widget.onLogout,
      bottomSheet: RidePanel(
        title: 'Driver Console',
        subtitle: 'Go online, accept requests, verify OTP, and complete the trip.',
        status: online ? 'ONLINE' : 'OFFLINE',
        statusWarning: !online,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final stackButtons = constraints.maxWidth < 560;
                final buttons = [
                  ElevatedButton.icon(
                    onPressed: loading ? null : () => updateStatus(true),
                    icon: const Icon(Icons.toggle_on_outlined),
                    label: const Text('Go Online'),
                  ),
                  OutlinedButton.icon(
                    onPressed: loading ? null : () => updateStatus(false),
                    icon: const Icon(Icons.toggle_off_outlined),
                    label: const Text('Go Offline'),
                  ),
                ];

                if (stackButtons) {
                  return Column(
                    children: [
                      buttons[0],
                      const SizedBox(height: 10),
                      buttons[1],
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: buttons[0]),
                    const SizedBox(width: 12),
                    Expanded(child: buttons[1]),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: loadRides,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Ride Requests'),
            ),
            const SizedBox(height: 16),
            if (rides.isEmpty)
              const EmptyCard(text: 'No active ride request.')
            else
              ...rides.map(
                (ride) => DriverRideCard(
                  ride: ride,
                  otpController: otpController,
                  onAction: rideAction,
                ),
              ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(message, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
    );
  }
}

class MapShell extends StatelessWidget {
  const MapShell({
    required this.user,
    required this.subtitle,
    required this.onLogout,
    required this.bottomSheet,
    super.key,
  });

  final AppUser user;
  final String subtitle;
  final VoidCallback onLogout;
  final Widget bottomSheet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                AppTopBar(user: user, subtitle: subtitle, onLogout: onLogout),
                const Expanded(child: DemoMap()),
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: bottomSheet,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    required this.user,
    required this.subtitle,
    required this.onLogout,
    super.key,
  });

  final AppUser user;
  final String subtitle;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          const AutoLogo(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RideMate AI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '$subtitle for ${user.fullName}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
    );
  }
}

class DemoMap extends StatelessWidget {
  const DemoMap({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MapPainter(),
      child: Stack(
        children: const [
          Positioned(
            left: 56,
            bottom: 190,
            child: MapPin(label: 'P', color: AppColors.green),
          ),
          Positioned(
            left: 160,
            bottom: 250,
            child: MapPin(
              label: 'C',
              color: AppColors.yellow,
              darkText: true,
            ),
          ),
          Positioned(
            right: 70,
            top: 128,
            child: MapPin(label: 'D', color: Color(0xFF276EF1)),
          ),
          Positioned(right: 150, bottom: 240, child: AutoMarker()),
        ],
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = AppColors.sky;
    canvas.drawRect(Offset.zero & size, background);

    final gridPaint = Paint()
      ..color = const Color(0x1A135068)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.82)
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;
    final roadLine = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(-40, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.42,
        size.width * 0.56,
        size.height * 0.58,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.72,
        size.width + 40,
        size.height * 0.28,
      );
    canvas.drawPath(path, roadPaint);
    canvas.drawPath(path, roadLine);

    final routePaint = Paint()
      ..color = AppColors.green
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.62),
      Offset(size.width * 0.72, size.height * 0.35),
      routePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RidePanel extends StatelessWidget {
  const RidePanel({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.child,
    this.statusWarning = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final String status;
  final bool statusWarning;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.96),
      borderRadius: BorderRadius.circular(8),
      elevation: 12,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height - 128,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(text: status, warning: statusWarning),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class RiderRideCard extends StatelessWidget {
  const RiderRideCard({required this.ride, super.key});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final driverText = ride.driver == null
        ? 'Searching for online driver'
        : '${ride.driver!.fullName} - ${ride.driverProfile?['vehicleNumber'] ?? 'Vehicle'}';

    return Column(
      children: [
        InfoRow(label: 'Pickup', value: ride.pickup),
        InfoRow(label: 'Destination Endpoint', value: ride.destination),
        InfoRow(
          label: 'Co-rider Pickup Distance',
          value: '${ride.coRiderPickupDistanceMeters} m away',
        ),
        InfoRow(label: 'Driver', value: driverText),
        InfoRow(
          label: 'ETA',
          value: ride.etaMinutes == null ? 'Waiting' : '${ride.etaMinutes} min',
        ),
        InfoRow(label: 'Estimated Shared Fare', value: 'Rs ${ride.estimatedFare}'),
        InfoRow(label: 'Ride OTP', value: ride.otp, highlight: true),
      ],
    );
  }
}

class DriverRideCard extends StatelessWidget {
  const DriverRideCard({
    required this.ride,
    required this.otpController,
    required this.onAction,
    super.key,
  });

  final Ride ride;
  final TextEditingController otpController;
  final Future<void> Function(Ride ride, String action) onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.soft,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoRow(label: 'Rider', value: ride.rider?.fullName ?? 'Rider'),
          InfoRow(label: 'Pickup', value: ride.pickup),
          InfoRow(label: 'Destination Endpoint', value: ride.destination),
          InfoRow(
            label: 'Co-rider Pickup Distance',
            value: '${ride.coRiderPickupDistanceMeters} m away',
          ),
          InfoRow(label: 'Status', value: ride.status),
          InfoRow(label: 'OTP From Rider', value: ride.otp, highlight: true),
          const SizedBox(height: 12),
          if (ride.status == 'MATCHED')
            ElevatedButton.icon(
              onPressed: () => onAction(ride, 'accept'),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Accept Ride'),
            ),
          if (ride.status == 'ACCEPTED') ...[
            TextFormField(
              controller: otpController,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => onAction(ride, 'start'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Ride'),
            ),
          ],
          if (ride.status == 'STARTED')
            ElevatedButton.icon(
              onPressed: () => onAction(ride, 'complete'),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Complete Ride'),
            ),
          if (ride.status != 'COMPLETED') ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => onAction(ride, 'cancel'),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Ride'),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
    super.key,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFDAF3E6) : AppColors.soft,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: highlight ? AppColors.greenDark : AppColors.ink,
                fontSize: highlight ? 20 : 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.soft,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.muted)),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.text,
    required this.warning,
    super.key,
  });

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: warning ? const Color(0xFFFFF0C3) : const Color(0xFFDAF3E6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: warning ? const Color(0xFF754800) : AppColors.greenDark,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class SegmentedControl extends StatelessWidget {
  const SegmentedControl({
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<String> values;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.soft,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          for (var index = 0; index < values.length; index++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                child: TextButton(
                  onPressed: () => onChanged(values[index]),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: selected == values[index]
                        ? AppColors.green
                        : Colors.transparent,
                    foregroundColor: selected == values[index]
                        ? Colors.white
                        : AppColors.muted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(labels[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({required this.light, super.key});

  final bool light;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AutoLogo(size: 56),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RideMate AI',
              style: TextStyle(
                color: light ? Colors.white : AppColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Shared auto matching',
              style: TextStyle(
                color: light ? const Color(0xFFDCEDE5) : AppColors.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AutoLogo extends StatelessWidget {
  const AutoLogo({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.local_taxi,
        color: AppColors.yellow,
        size: size * 0.62,
      ),
    );
  }
}

class AutoMarker extends StatelessWidget {
  const AutoMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.yellow,
        border: Border.all(color: Colors.white, width: 4),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33152028),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.local_taxi, color: AppColors.ink),
    );
  }
}

class MapPin extends StatelessWidget {
  const MapPin({
    required this.label,
    required this.color,
    this.darkText = false,
    super.key,
  });

  final String label;
  final Color color;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.white, width: 4),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A152028),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: darkText ? AppColors.ink : Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
