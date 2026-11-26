import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/user_model.dart';
import '../../models/medicine_model.dart';
import '../../models/medicine_history_model.dart';
import '../../models/health_record_model.dart';

class PdfReportService {
  static Future<Uint8List> generateHealthReport({
    required UserModel user,
    required List<MedicineModel> medicines,
    required List<MedicineHistoryModel> history,
    required List<HealthRecordModel> healthRecords,
    required DateTime startDate,
    required DateTime endDate,
    required double adherenceRate,
  }) async {
    final pdf = pw.Document();

    final activeMeds = medicines.where((m) => m.isActive).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#2563EB'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CareTrack Patient Health Report',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Your Health, Your Responsibility',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Generated:',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                      ),
                      pw.Text(
                        DateTime.now().toString().substring(0, 16),
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // Patient Demographics Section
            pw.Text('1. Patient Profile Information', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(children: [
                  pw.Text('Name:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(user.name, style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Age / Gender:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('${user.age} yrs / ${user.gender}', style: const pw.TextStyle(fontSize: 10)),
                ]),
                pw.TableRow(children: [
                  pw.Text('Blood Group:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(user.bloodGroup, style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Height / Weight:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('${user.height} cm / ${user.weight} kg', style: const pw.TextStyle(fontSize: 10)),
                ]),
                pw.TableRow(children: [
                  pw.Text('Emergency Contact:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('${user.emergencyContactName} (${user.emergencyContactPhone})', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Allergies:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(user.allergies.isNotEmpty ? user.allergies : 'None reported', style: const pw.TextStyle(fontSize: 10)),
                ]),
                if (user.medicalHistory.isNotEmpty)
                  pw.TableRow(children: [
                    pw.Text('Conditions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(user.medicalHistory, style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Report Period:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('${startDate.toString().substring(0, 10)} to ${endDate.toString().substring(0, 10)}', style: const pw.TextStyle(fontSize: 10)),
                  ]),
              ],
            ),
            pw.SizedBox(height: 20),

            // Medication Adherence Summary
            pw.Text('2. Medication Adherence Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F1F5F9'),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('Overall Adherence Rate', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text('${adherenceRate.toStringAsFixed(1)}%',
                            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2563EB'))),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F1F5F9'),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('Active Prescriptions', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text('${activeMeds.length}',
                            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#10B981'))),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F1F5F9'),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('Total Dose Logs', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text('${history.length}',
                            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#F59E0B'))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Active Medicines Table
            pw.Text('3. Active Prescriptions & Schedules', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            if (activeMeds.isEmpty)
              pw.Text('No active medicines registered.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
            else
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#2563EB')),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                headers: ['Medicine', 'Type', 'Dosage', 'Frequency', 'Timing', 'Stock'],
                data: activeMeds.map((m) {
                  return [
                    m.name,
                    m.medicineType,
                    m.dosage,
                    m.frequency,
                    m.foodTiming,
                    '${m.remainingStock}/${m.totalStock}',
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 20),

            // Health Vitals Log Table
            pw.Text('4. Recent Health Vitals Logs', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            if (healthRecords.isEmpty)
              pw.Text('No health vitals recorded during this period.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
            else
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#14B8A6')),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                headers: ['Metric Type', 'Reading', 'Context / Notes', 'Date & Time'],
                data: healthRecords.take(15).map((r) {
                  final dt = DateTime.tryParse(r.recordedAt);
                  return [
                    r.displayName,
                    r.formattedValue,
                    r.notes?.isNotEmpty == true ? r.notes! : (r.mealContext ?? '-'),
                    dt != null ? dt.toString().substring(0, 16) : r.recordedAt,
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 20),

            // Medical Disclaimer Footer
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'Notice: This CareTrack report is generated based on patient-recorded inputs for monitoring and consultation purposes. It does not replace certified diagnostic procedures or professional medical judgment.',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> sharePdfReport({
    required Uint8List pdfBytes,
    required String filename,
  }) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }

  static Future<File> savePdfLocally({
    required Uint8List pdfBytes,
    required String filename,
  }) async {
    final outputDir = await getApplicationDocumentsDirectory();
    final file = File('${outputDir.path}/$filename');
    await file.writeAsBytes(pdfBytes);
    return file;
  }
}
