import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../models/medicine_model.dart';
import '../../../models/medicine_schedule_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/medicine_provider.dart';
import '../../widgets/custom_text_field.dart';

class AddEditMedicineScreen extends StatefulWidget {
  final MedicineModel? medicine;
  const AddEditMedicineScreen({super.key, this.medicine});

  @override
  State<AddEditMedicineScreen> createState() => _AddEditMedicineScreenState();
}

class _AddEditMedicineScreenState extends State<AddEditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _instructionsController;
  late TextEditingController _totalStockController;
  late TextEditingController _remainingStockController;
  late TextEditingController _lowStockThresholdController;

  String _medicineType = 'Tablet';
  String _frequency = 'Once daily';
  String _foodTiming = 'After food';
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isActive = true;

  List<TimeOfDay> _scheduleTimes = [const TimeOfDay(hour: 8, minute: 0)];

  final List<String> _medicineTypes = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Injection',
    'Drops',
    'Inhaler',
    'Ointment',
    'Other'
  ];

  final List<String> _frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Every 8 hours',
    'Every 12 hours',
    'As needed',
  ];

  final List<String> _foodTimings = [
    'Before food',
    'After food',
    'With food',
    'Empty stomach',
  ];

  @override
  void initState() {
    super.initState();
    final med = widget.medicine;
    if (med != null) {
      _nameController = TextEditingController(text: med.name);
      _dosageController = TextEditingController(text: med.dosage);
      _instructionsController = TextEditingController(text: med.instructions);
      _totalStockController = TextEditingController(text: med.totalStock.toString());
      _remainingStockController = TextEditingController(text: med.remainingStock.toString());
      _lowStockThresholdController = TextEditingController(text: med.lowStockThreshold.toString());
      _medicineType = med.medicineType;
      _frequency = med.frequency;
      _foodTiming = med.foodTiming;
      _startDate = DateTime.tryParse(med.startDate) ?? DateTime.now();
      _endDate = DateTime.tryParse(med.endDate) ?? DateTime.now().add(const Duration(days: 30));
      _isActive = med.isActive;

      if (med.schedules.isNotEmpty) {
        _scheduleTimes = med.schedules.map((s) => AppDateUtils.parseTimeOfDay(s.timeOfDay)).toList();
      }
    } else {
      _nameController = TextEditingController();
      _dosageController = TextEditingController(text: '1 Tablet');
      _instructionsController = TextEditingController();
      _totalStockController = TextEditingController(text: '30');
      _remainingStockController = TextEditingController(text: '30');
      _lowStockThresholdController = TextEditingController(text: '5');
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _totalStockController.dispose();
    _remainingStockController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  void _onFrequencyChanged(String? val) {
    if (val == null) return;
    setState(() {
      _frequency = val;
      if (val == 'Once daily') {
        _scheduleTimes = [const TimeOfDay(hour: 8, minute: 0)];
      } else if (val == 'Twice daily') {
        _scheduleTimes = [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ];
      } else if (val == 'Three times daily') {
        _scheduleTimes = [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 14, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ];
      } else if (val == 'Every 8 hours') {
        _scheduleTimes = [
          const TimeOfDay(hour: 6, minute: 0),
          const TimeOfDay(hour: 14, minute: 0),
          const TimeOfDay(hour: 22, minute: 0),
        ];
      }
    });
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduleTimes[index],
    );
    if (picked != null) {
      setState(() {
        _scheduleTimes[index] = picked;
      });
    }
  }

  void _addScheduleTime() {
    setState(() {
      _scheduleTimes.add(const TimeOfDay(hour: 12, minute: 0));
    });
  }

  void _removeScheduleTime(int index) {
    if (_scheduleTimes.length <= 1) return;
    setState(() {
      _scheduleTimes.removeAt(index);
    });
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final medProvider = Provider.of<MedicineProvider>(context, listen: false);
    final userId = auth.currentUser?.id ?? 1;

    final totalStock = int.tryParse(_totalStockController.text) ?? 30;
    final remainingStock = int.tryParse(_remainingStockController.text) ?? totalStock;
    final lowStockThreshold = int.tryParse(_lowStockThresholdController.text) ?? 5;

    final now = DateTime.now().toIso8601String();
    final isEditing = widget.medicine != null;

    // Build Schedules
    final schedules = _scheduleTimes.asMap().entries.map((entry) {
      final idx = entry.key;
      final time = entry.value;
      final timeStr = AppDateUtils.formatTimeOfDay(time);
      final notifId = (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 100000 + idx;

      return MedicineScheduleModel(
        medicineId: widget.medicine?.id ?? 0,
        timeOfDay: timeStr,
        notificationId: notifId,
        dosageAmount: _dosageController.text.trim(),
        isEnabled: true,
      );
    }).toList();

    final med = MedicineModel(
      id: widget.medicine?.id,
      userId: userId,
      name: _nameController.text.trim(),
      medicineType: _medicineType,
      dosage: _dosageController.text.trim(),
      frequency: _frequency,
      startDate: AppDateUtils.formatIsoDate(_startDate),
      endDate: AppDateUtils.formatIsoDate(_endDate),
      foodTiming: _foodTiming,
      instructions: _instructionsController.text.trim(),
      totalStock: totalStock,
      remainingStock: remainingStock,
      lowStockThreshold: lowStockThreshold,
      isActive: _isActive,
      createdAt: widget.medicine?.createdAt ?? now,
      updatedAt: now,
      schedules: schedules,
    );

    bool success;
    if (isEditing) {
      success = await medProvider.updateMedicine(med);
    } else {
      success = await medProvider.addMedicine(med);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Medicine updated successfully' : 'Medicine added with reminders!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(medProvider.errorMessage ?? 'Failed to save medicine'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.medicine != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Medicine' : 'Add New Medicine'),
        actions: [
          TextButton(
            onPressed: _saveMedicine,
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
                label: 'Medicine Name *',
                hint: 'e.g. Amoxicillin, Metformin, Lisinopril',
                prefixIcon: Icons.medication_rounded,
                validator: (v) => Validators.validateRequired(v, 'Medicine Name'),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Medicine Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _medicineType,
                          items: _medicineTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) => setState(() => _medicineType = val!),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomTextField(
                      controller: _dosageController,
                      label: 'Dosage *',
                      hint: 'e.g. 500 mg, 10 ml',
                      validator: (v) => Validators.validateRequired(v, 'Dosage'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Frequency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _frequency,
                          items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                          onChanged: _onFrequencyChanged,
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Meal Timing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _foodTiming,
                          items: _foodTimings.map((ft) => DropdownMenuItem(value: ft, child: Text(ft))).toList(),
                          onChanged: (val) => setState(() => _foodTiming = val!),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Reminder Timings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reminder Schedule Times',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                    tooltip: 'Add Time',
                    onPressed: _addScheduleTime,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: List.generate(_scheduleTimes.length, (idx) {
                      final time = _scheduleTimes[idx];
                      return ListTile(
                        leading: const Icon(Icons.alarm, color: AppColors.primary),
                        title: Text(
                          AppDateUtils.formatTimeString(AppDateUtils.formatTimeOfDay(time)),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _pickTime(idx),
                            ),
                            if (_scheduleTimes.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                                onPressed: () => _removeScheduleTime(idx),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date Range
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                        ),
                        child: Text(AppDateUtils.formatDate(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setState(() => _endDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          prefixIcon: Icon(Icons.event_available_rounded, size: 18),
                        ),
                        child: Text(AppDateUtils.formatDate(_endDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Stock Management
              const Text(
                'Stock Tracking & Low-Stock Alert',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _totalStockController,
                      label: 'Total Stock',
                      hint: '30',
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.validateNumber(v, 'Total Stock', min: 0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      controller: _remainingStockController,
                      label: 'Remaining',
                      hint: '30',
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.validateNumber(v, 'Remaining Stock', min: 0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      controller: _lowStockThresholdController,
                      label: 'Alert At',
                      hint: '5',
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.validateNumber(v, 'Alert Threshold', min: 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _instructionsController,
                label: 'Instructions / Notes',
                hint: 'e.g. Take with a full glass of water. Do not lie down for 30 minutes.',
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              if (isEditing)
                SwitchListTile(
                  title: const Text('Active Medicine'),
                  subtitle: const Text('Inactive medicines do not trigger scheduled notifications'),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveMedicine,
                child: Text(isEditing ? 'Update Medicine' : 'Save & Schedule Reminders'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
