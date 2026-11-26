import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/health_reference.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../models/health_record_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/health_provider.dart';
import '../../widgets/custom_text_field.dart';

class AddHealthRecordScreen extends StatefulWidget {
  final HealthRecordModel? record;
  final String? initialType;

  const AddHealthRecordScreen({super.key, this.record, this.initialType});

  @override
  State<AddHealthRecordScreen> createState() => _AddHealthRecordScreenState();
}

class _AddHealthRecordScreenState extends State<AddHealthRecordScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _recordType;
  late TextEditingController _primaryValController;
  late TextEditingController _secondaryValController;
  late TextEditingController _notesController;

  late DateTime _recordedDate;
  late TimeOfDay _recordedTime;
  String _mealContext = 'Fasting';
  String _unit = 'mmHg';

  final List<Map<String, dynamic>> _types = [
    {'id': 'blood_pressure', 'name': 'Blood Pressure', 'unit': 'mmHg', 'icon': Icons.favorite_rounded},
    {'id': 'blood_glucose', 'name': 'Blood Glucose', 'unit': 'mg/dL', 'icon': Icons.bloodtype_rounded},
    {'id': 'heart_rate', 'name': 'Heart Rate', 'unit': 'bpm', 'icon': Icons.monitor_heart_rounded},
    {'id': 'body_temperature', 'name': 'Body Temperature', 'unit': '°C', 'icon': Icons.thermostat_rounded},
    {'id': 'oxygen_saturation', 'name': 'Oxygen Saturation (SpO2)', 'unit': '%', 'icon': Icons.air_rounded},
    {'id': 'weight', 'name': 'Weight', 'unit': 'kg', 'icon': Icons.scale_rounded},
    {'id': 'height', 'name': 'Height', 'unit': 'cm', 'icon': Icons.height_rounded},
  ];

  @override
  void initState() {
    super.initState();
    final rec = widget.record;
    if (rec != null) {
      _recordType = rec.recordType;
      _primaryValController = TextEditingController(text: rec.valuePrimary.toString());
      _secondaryValController = TextEditingController(text: rec.valueSecondary?.toString() ?? '');
      _notesController = TextEditingController(text: rec.notes ?? '');
      _unit = rec.unit;
      _mealContext = rec.mealContext ?? 'Fasting';

      final dt = DateTime.tryParse(rec.recordedAt) ?? DateTime.now();
      _recordedDate = dt;
      _recordedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    } else {
      _recordType = widget.initialType ?? 'blood_pressure';
      _primaryValController = TextEditingController();
      _secondaryValController = TextEditingController();
      _notesController = TextEditingController();
      _recordedDate = DateTime.now();
      _recordedTime = TimeOfDay.now();
      _updateUnitForType(_recordType);
    }
  }

  void _updateUnitForType(String type) {
    final match = _types.firstWhere((t) => t['id'] == type, orElse: () => _types.first);
    setState(() {
      _unit = match['unit'];
    });
  }

  @override
  void dispose() {
    _primaryValController.dispose();
    _secondaryValController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  HealthRangeResult? _getLiveEvaluation() {
    final pVal = double.tryParse(_primaryValController.text);
    if (pVal == null) return null;

    if (_recordType == 'blood_pressure') {
      final sVal = double.tryParse(_secondaryValController.text);
      if (sVal != null) {
        return HealthReference.evaluateBloodPressure(pVal, sVal);
      }
    } else if (_recordType == 'blood_glucose') {
      return HealthReference.evaluateBloodGlucose(pVal, context: _mealContext);
    } else if (_recordType == 'heart_rate') {
      return HealthReference.evaluateHeartRate(pVal);
    } else if (_recordType == 'body_temperature') {
      return HealthReference.evaluateBodyTemperature(pVal);
    } else if (_recordType == 'oxygen_saturation') {
      return HealthReference.evaluateSpO2(pVal);
    }
    return null;
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);
    final userId = auth.currentUser?.id ?? 1;

    final pVal = double.parse(_primaryValController.text.trim());
    final sVal = _recordType == 'blood_pressure' && _secondaryValController.text.isNotEmpty
        ? double.tryParse(_secondaryValController.text.trim())
        : null;

    final recordedDateTime = DateTime(
      _recordedDate.year,
      _recordedDate.month,
      _recordedDate.day,
      _recordedTime.hour,
      _recordedTime.minute,
    );

    final now = DateTime.now().toIso8601String();
    final isEditing = widget.record != null;

    final newRecord = HealthRecordModel(
      id: widget.record?.id,
      userId: userId,
      recordType: _recordType,
      valuePrimary: pVal,
      valueSecondary: sVal,
      unit: _unit,
      recordedAt: recordedDateTime.toIso8601String(),
      mealContext: _recordType == 'blood_glucose' ? _mealContext : null,
      notes: _notesController.text.trim(),
      createdAt: widget.record?.createdAt ?? now,
    );

    bool success;
    if (isEditing) {
      success = await healthProvider.updateRecord(newRecord);
    } else {
      success = await healthProvider.addRecord(newRecord);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Health record updated' : 'Health record logged successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(healthProvider.errorMessage ?? 'Failed to save health record'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.record != null;
    final eval = _getLiveEvaluation();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Health Record' : 'Log Health Metric'),
        actions: [
          TextButton(
            onPressed: _saveRecord,
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
              // Metric Selector
              if (!isEditing) ...[
                const Text('Select Metric Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _recordType,
                  items: _types.map((t) {
                    return DropdownMenuItem<String>(
                      value: t['id'] as String,
                      child: Row(
                        children: [
                          Icon(t['icon'] as IconData, size: 20, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(t['name'] as String),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _recordType = val;
                        _updateUnitForType(val);
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Metric Value Fields
              if (_recordType == 'blood_pressure') ...[
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _primaryValController,
                        label: 'Systolic (mmHg) *',
                        hint: 'e.g. 120',
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.validateNumber(v, 'Systolic', min: 50, max: 260),
                        onTap: () => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CustomTextField(
                        controller: _secondaryValController,
                        label: 'Diastolic (mmHg) *',
                        hint: 'e.g. 80',
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.validateNumber(v, 'Diastolic', min: 30, max: 180),
                        onTap: () => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                CustomTextField(
                  controller: _primaryValController,
                  label: 'Reading Value ($_unit) *',
                  hint: _getHintForType(_recordType),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => Validators.validateNumber(v, 'Reading'),
                  onTap: () => setState(() {}),
                ),
              ],
              const SizedBox(height: 16),

              // Meal Context for Blood Glucose
              if (_recordType == 'blood_glucose') ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Testing Context', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _mealContext,
                      items: const ['Fasting', 'Before Meal', '2-Hours Post-Meal', 'Random', 'Bedtime']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) => setState(() => _mealContext = val!),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Live General Reference Range Box
              if (eval != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: eval.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: eval.color.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_rounded, color: eval.color, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Status: ${eval.status}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: eval.color, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eval.description,
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eval.referenceInfo,
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Date and Time Pickers
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _recordedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _recordedDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                        ),
                        child: Text(AppDateUtils.formatDate(_recordedDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _recordedTime,
                        );
                        if (picked != null) setState(() => _recordedTime = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          prefixIcon: Icon(Icons.access_time_rounded, size: 18),
                        ),
                        child: Text(AppDateUtils.formatTimeOfDay(_recordedTime)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _notesController,
                label: 'Notes / Symptoms',
                hint: 'e.g. Mild headache, after light jogging, felt relaxed',
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Educational Medical Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  HealthReference.disclaimer,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saveRecord,
                child: Text(isEditing ? 'Update Health Record' : 'Save Health Record'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getHintForType(String type) {
    switch (type) {
      case 'blood_glucose':
        return 'e.g. 95';
      case 'heart_rate':
        return 'e.g. 72';
      case 'body_temperature':
        return 'e.g. 36.8';
      case 'oxygen_saturation':
        return 'e.g. 98';
      case 'weight':
        return 'e.g. 72.5';
      case 'height':
        return 'e.g. 175';
      default:
        return 'Enter value';
    }
  }
}
