part of ridemate_ai;

class AppField extends StatelessWidget {
  const AppField({
    required this.label,
    required this.controller,
    this.icon,
    this.obscureText = false,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: AppColors.ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.muted),
        prefixIcon: icon != null ? Icon(icon, color: AppColors.muted) : null,
        filled: true,
        fillColor: AppColors.cardAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
