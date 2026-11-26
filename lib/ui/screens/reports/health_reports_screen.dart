import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/medicine_provider.dart';
import '../../../providers/health_provider.dart';

class HealthReportsScreen extends StatefulWidget {
  const HealthReportsScreen({super.key});

  @override
  State<HealthReportsScreen> createState() => _HealthReportsScreenState();
}

class _HealthReportsScreenState extends State<HealthReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;
  Uint8List? _generatedPdf;

  Future<void> _generateReport() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final med = Provider.of<MedicineProvider>(context, listen: false);
    final health = Provider.of<HealthProvider>(context, listen: false);
    final user = auth.currentUser;

    if (user == null) return;

    setState(() => _isGenerating = true);

    try {
      final adherence = med.calculateAdherence();
      final pdfBytes = await PdfReportService.generateHealthReport(
        user: user,
        medicines: med.allMedicines,
        history: med.history,
        healthRecords: health.records,
        startDate: _startDate,
        endDate: _endDate,
        adherenceRate: adherence,
      );

      setState(() {
        _generatedPdf = pdfBytes;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF report: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _shareReport() async {
    if (_generatedPdf == null) return;
    final filename = 'CareTrack_Report_${AppDateUtils.formatIsoDate(DateTime.now())}.pdf';
    await PdfReportService.sharePdfReport(pdfBytes: _generatedPdf!, filename: filename);
  }

  Future<void> _saveReport() async {
    if (_generatedPdf == null) return;
    try {
      final filename = 'CareTrack_Report_${AppDateUtils.formatIsoDate(DateTime.now())}.pdf';
      final file = await PdfReportService.savePdfLocally(pdfBytes: _generatedPdf!, filename: filename);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved successfully to: ${file.path}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save report: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Health Reports'),
        actions: [
          if (_generatedPdf != null) ...[
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share Report',
              onPressed: _shareReport,
            ),
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Save Report',
              onPressed: _saveReport,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Report Generator Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Generate Health Summary',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Export patient vitals, adherence & prescriptions to PDF',
                                style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Select Report Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime(2020),
                                lastDate: _endDate,
                              );
                              if (picked != null) setState(() => _startDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'From',
                                prefixIcon: Icon(Icons.date_range_rounded, size: 18),
                              ),
                              child: Text(AppDateUtils.formatDate(_startDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate,
                                firstDate: _startDate,
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) setState(() => _endDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'To',
                                prefixIcon: Icon(Icons.event_rounded, size: 18),
                              ),
                              child: Text(AppDateUtils.formatDate(_endDate)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateReport,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(_isGenerating ? 'Generating PDF...' : 'Generate PDF Report'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Live Preview or Helper Placeholder
            if (_generatedPdf != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Document Preview', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _shareReport,
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('Share'),
                      ),
                      TextButton.icon(
                        onPressed: _saveReport,
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 480,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: PdfPreview(
                    build: (format) => _generatedPdf!,
                    allowPrinting: true,
                    allowSharing: true,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    initialPageFormat: PdfPageFormat.a4,
                  ),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Icon(Icons.description_outlined, size: 54, color: isDark ? AppColors.darkTextSecondary : const Color(0xFFCBD5E1)),
                      const SizedBox(height: 12),
                      const Text(
                        'Ready to Export',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Click "Generate PDF Report" above to compile patient vitals, medication adherence logs, and prescriptions into a shareable clinical document.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
