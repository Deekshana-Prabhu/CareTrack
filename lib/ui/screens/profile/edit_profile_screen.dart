import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _medicalHistoryController;
  late TextEditingController _allergiesController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;

  late String _gender;
  late String _bloodGroup;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameController = TextEditingController(text: u.name);
    _ageController = TextEditingController(text: u.age.toString());
    _heightController = TextEditingController(text: u.height.toString());
    _weightController = TextEditingController(text: u.weight.toString());
    _medicalHistoryController = TextEditingController(text: u.medicalHistory);
    _allergiesController = TextEditingController(text: u.allergies);
    _emergencyNameController = TextEditingController(text: u.emergencyContactName);
    _emergencyPhoneController = TextEditingController(text: u.emergencyContactPhone);

    _gender = _genders.contains(u.gender) ? u.gender : 'Male';
    _bloodGroup = _bloodGroups.contains(u.bloodGroup) ? u.bloodGroup : 'A+';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    final updated = widget.user.copyWith(
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text) ?? widget.user.age,
      gender: _gender,
      height: double.tryParse(_heightController.text) ?? widget.user.height,
      weight: double.tryParse(_weightController.text) ?? widget.user.weight,
      bloodGroup: _bloodGroup,
      medicalHistory: _medicalHistoryController.text.trim(),
      allergies: _allergiesController.text.trim(),
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    final success = await auth.updateProfile(updated);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Update failed'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Full Name *',
                prefixIcon: Icons.person_rounded,
                validator: (v) => Validators.validateRequired(v, 'Name'),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _ageController,
                      label: 'Age *',
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
                          onChanged: (v) => setState(() => _gender = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _heightController,
                      label: 'Height (cm) *',
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.validateNumber(v, 'Height', min: 30, max: 250),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomTextField(
                      controller: _weightController,
                      label: 'Weight (kg) *',
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.validateNumber(v, 'Weight', min: 2, max: 300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Blood Group *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _bloodGroup,
                    items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
                    onChanged: (v) => setState(() => _bloodGroup = v!),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text('Medical Information', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              const Divider(),
              const SizedBox(height: 8),

              CustomTextField(
                controller: _medicalHistoryController,
                label: 'Medical Conditions',
                hint: 'e.g. Hypertension, Asthma',
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _allergiesController,
                label: 'Known Allergies',
                hint: 'e.g. Penicillin, Peanuts',
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              const Text('Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              const Divider(),
              const SizedBox(height: 8),

              CustomTextField(
                controller: _emergencyNameController,
                label: 'Contact Name',
                prefixIcon: Icons.contact_emergency_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _emergencyPhoneController,
                label: 'Contact Phone Number',
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
