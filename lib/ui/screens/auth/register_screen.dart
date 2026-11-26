import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/medicine_provider.dart';
import '../../../providers/health_provider.dart';
import '../../../providers/appointment_provider.dart';
import '../home/main_navigation_screen.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  String _gender = 'Male';
  String _bloodGroup = 'A+';
  bool _obscurePassword = true;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final med = Provider.of<MedicineProvider>(context, listen: false);
    final health = Provider.of<HealthProvider>(context, listen: false);

    final success = await auth.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      age: int.tryParse(_ageController.text) ?? 25,
      gender: _gender,
      height: double.tryParse(_heightController.text) ?? 170.0,
      weight: double.tryParse(_weightController.text) ?? 70.0,
      bloodGroup: _bloodGroup,
      medicalHistory: _medicalHistoryController.text,
      allergies: _allergiesController.text,
      emergencyContactName: _emergencyNameController.text,
      emergencyContactPhone: _emergencyPhoneController.text,
    );

    if (!mounted) return;

    if (success && auth.currentUser != null) {
      final user = auth.currentUser!;
      await med.loadMedicines(user.id!);
      await health.loadHealthData(user.id!);
      await Provider.of<AppointmentProvider>(context, listen: false).loadAppointments(user.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Welcome to CareTrack.'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registration failed. Try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Patient Registration'),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Your Health Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter patient details to personalize medicine reminders & vitals monitoring.',
                  style: TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
                ),
                const SizedBox(height: 24),

                // Account Credentials
                const Text('Account Information', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                const Divider(),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name *',
                  hint: 'John Doe',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => Validators.validateRequired(v, 'Full Name'),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address *',
                  hint: 'patient@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password (min 6 characters) *',
                  hint: 'Create a secure password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  validator: Validators.validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.lightTextSecondary,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 24),

                // Physical & Demographic Details
                const Text('Health & Demographics', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _ageController,
                        label: 'Age *',
                        hint: 'e.g. 35',
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.validateNumber(v, 'Age', min: 1, max: 120),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gender *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _gender,
                            items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                            onChanged: (val) => setState(() => _gender = val!),
                            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _heightController,
                        label: 'Height (cm) *',
                        hint: '175',
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.validateNumber(v, 'Height', min: 30, max: 250),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CustomTextField(
                        controller: _weightController,
                        label: 'Weight (kg) *',
                        hint: '70',
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.validateNumber(v, 'Weight', min: 2, max: 300),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Blood Group *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _bloodGroup,
                      items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
                      onChanged: (val) => setState(() => _bloodGroup = val!),
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Medical History & Allergies
                const Text('Medical Background', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                const Divider(),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _medicalHistoryController,
                  label: 'Medical History / Chronic Conditions',
                  hint: 'e.g. Hypertension, Type 2 Diabetes, Asthma (Optional)',
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _allergiesController,
                  label: 'Known Allergies',
                  hint: 'e.g. Penicillin, Peanuts, Sulfa drugs (Optional)',
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Emergency Contact
                const Text('Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                const Divider(),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _emergencyNameController,
                  label: 'Emergency Contact Name',
                  hint: 'e.g. Jane Doe (Spouse/Parent)',
                  prefixIcon: Icons.contact_emergency_outlined,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _emergencyPhoneController,
                  label: 'Emergency Contact Phone',
                  hint: '+1 555-0199',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleRegister,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Complete Registration', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
