import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../models/appointment_model.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';

class AddEditAppointmentScreen extends StatefulWidget {
  final AppointmentModel? appointment;
  const AddEditAppointmentScreen({super.key, this.appointment});

  @override
  State<AddEditAppointmentScreen> createState() => _AddEditAppointmentScreenState();
}

class _AddEditAppointmentScreenState extends State<AddEditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _doctorController;
  late TextEditingController _hospitalController;
  late TextEditingController _reasonController;
  late TextEditingController _notesController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _specialization = 'General Physician';
  int _reminderMinutesBefore = 60; // 30, 60, 120, 1440 (1 day)

  final List<String> _specializations = [
    'General Physician',
    'Cardiologist',
    'Endocrinologist',
    'Neurologist',
    'Dermatologist',
    'Orthopedic',
    'Pulmonologist',
    'Gastroenterologist',
    'Ophthalmologist',
    'Dentist',
    'Psychiatrist',
    'Other Specialist',
  ];

  final List<Map<String, dynamic>> _reminderOptions = [
    {'label': '30 minutes before', 'minutes': 30},
    {'label': '1 hour before', 'minutes': 60},
    {'label': '2 hours before', 'minutes': 120},
    {'label': '1 day before', 'minutes': 1440},
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.appointment;
    if (a != null) {
      _doctorController = TextEditingController(text: a.doctorName);
      _hospitalController = TextEditingController(text: a.hospitalName);
      _reasonController = TextEditingController(text: a.reason);
      _notesController = TextEditingController(text: a.notes);
      _specialization = _specializations.contains(a.specialization) ? a.specialization : 'Other Specialist';

      final dt = DateTime.tryParse(a.appointmentDate) ?? DateTime.now().add(const Duration(days: 1));
      _selectedDate = dt;
      _selectedTime = AppDateUtils.parseTimeOfDay(a.appointmentTime);
    } else {
      _doctorController = TextEditingController();
      _hospitalController = TextEditingController();
      _reasonController = TextEditingController();
      _notesController = TextEditingController();
      _selectedDate = DateTime.now().add(const Duration(days: 2));
      _selectedTime = const TimeOfDay(hour: 10, minute: 30);
    }
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _hospitalController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final apptProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final userId = auth.currentUser?.id ?? 1;

    final now = DateTime.now().toIso8601String();
    final isEditing = widget.appointment != null;
    final notifId = isEditing
        ? widget.appointment!.notificationId
        : ((DateTime.now().millisecondsSinceEpoch ~/ 1000) % 100000) + 70000;

    final appt = AppointmentModel(
      id: widget.appointment?.id,
      userId: userId,
      doctorName: _doctorController.text.trim(),
      hospitalName: _hospitalController.text.trim(),
      appointmentDate: AppDateUtils.formatIsoDate(_selectedDate),
      appointmentTime: AppDateUtils.formatTimeOfDay(_selectedTime),
      specialization: _specialization,
      reason: _reasonController.text.trim(),
      notes: _notesController.text.trim(),
      notificationId: notifId,
      isCompleted: widget.appointment?.isCompleted ?? false,
      createdAt: widget.appointment?.createdAt ?? now,
    );

    bool success;
    if (isEditing) {
      success = await apptProvider.updateAppointment(appt, reminderMinutes: _reminderMinutesBefore);
    } else {
      success = await apptProvider.addAppointment(appt, reminderMinutes: _reminderMinutesBefore);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Appointment updated' : 'Appointment booked & reminder scheduled!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(apptProvider.errorMessage ?? 'Failed to save appointment'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.appointment != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Appointment' : 'Book Appointment'),
        actions: [
          TextButton(
            onPressed: _saveAppointment,
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
                controller: _doctorController,
                label: 'Doctor\'s Name *',
                hint: 'e.g. Dr. Sarah Jenkins',
                prefixIcon: Icons.person_rounded,
                validator: (v) => Validators.validateRequired(v, 'Doctor Name'),
              ),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Doctor\'s Specialization *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _specialization,
                    items: _specializations.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _specialization = val!),
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _hospitalController,
                label: 'Hospital or Clinic Name *',
                hint: 'e.g. City General Hospital, Suite 402',
                prefixIcon: Icons.local_hospital_rounded,
                validator: (v) => Validators.validateRequired(v, 'Hospital / Clinic Name'),
              ),
              const SizedBox(height: 16),

              // Date and Time Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Appointment Date *',
                          prefixIcon: Icon(Icons.calendar_month_rounded, size: 18),
                        ),
                        child: Text(AppDateUtils.formatDate(_selectedDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (picked != null) setState(() => _selectedTime = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time *',
                          prefixIcon: Icon(Icons.access_time_rounded, size: 18),
                        ),
                        child: Text(AppDateUtils.formatTimeOfDay(_selectedTime)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reminder Notification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: _reminderMinutesBefore,
                    items: _reminderOptions.map((opt) {
                      return DropdownMenuItem<int>(
                        value: opt['minutes'] as int,
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_active_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(opt['label'] as String),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _reminderMinutesBefore = val!),
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _reasonController,
                label: 'Reason for Appointment *',
                hint: 'e.g. Routine blood pressure review, Quarterly diabetes checkup',
                validator: (v) => Validators.validateRequired(v, 'Reason for appointment'),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _notesController,
                label: 'Optional Notes / Instructions',
                hint: 'e.g. Bring fasting test results, do not eat 8 hrs prior',
                maxLines: 2,
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _saveAppointment,
                child: Text(isEditing ? 'Update Appointment' : 'Schedule Appointment'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
