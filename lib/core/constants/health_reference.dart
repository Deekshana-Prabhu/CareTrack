import 'package:flutter/material.dart';
import 'app_colors.dart';

class HealthRangeResult {
  final String status;
  final String description;
  final Color color;
  final String referenceInfo;

  const HealthRangeResult({
    required this.status,
    required this.description,
    required this.color,
    required this.referenceInfo,
  });
}

class HealthReference {
  static const String disclaimer = 
      'Disclaimer: Reference ranges are for general information only and do not constitute medical diagnosis. Consult a healthcare provider for personalized medical advice.';

  // Blood Pressure Evaluation
  static HealthRangeResult evaluateBloodPressure(double systolic, double diastolic) {
    if (systolic < 120 && diastolic < 80) {
      return const HealthRangeResult(
        status: 'Normal',
        description: 'Optimal blood pressure levels',
        color: AppColors.success,
        referenceInfo: 'Standard normal: Systolic < 120 & Diastolic < 80 mmHg',
      );
    } else if (systolic <= 129 && diastolic < 80) {
      return const HealthRangeResult(
        status: 'Elevated',
        description: 'Slightly higher than normal',
        color: AppColors.warning,
        referenceInfo: 'Elevated range: Systolic 120-129 & Diastolic < 80 mmHg',
      );
    } else if ((systolic >= 130 && systolic <= 139) || (diastolic >= 80 && diastolic <= 89)) {
      return const HealthRangeResult(
        status: 'Stage 1 Hypertension',
        description: 'Mildly high blood pressure',
        color: Color(0xFFF97316), // Orange
        referenceInfo: 'Stage 1: Systolic 130-139 or Diastolic 80-89 mmHg',
      );
    } else {
      return const HealthRangeResult(
        status: 'Stage 2 Hypertension',
        description: 'High blood pressure reading',
        color: AppColors.danger,
        referenceInfo: 'Stage 2: Systolic ≥ 140 or Diastolic ≥ 90 mmHg',
      );
    }
  }

  // Blood Glucose Evaluation (mg/dL)
  static HealthRangeResult evaluateBloodGlucose(double glucose, {String context = 'Fasting'}) {
    final isFasting = context.toLowerCase().contains('fasting');
    if (isFasting) {
      if (glucose < 70) {
        return const HealthRangeResult(
          status: 'Low (Hypoglycemia)',
          description: 'Blood sugar is lower than standard range',
          color: AppColors.warning,
          referenceInfo: 'Fasting normal: 70 - 99 mg/dL',
        );
      } else if (glucose <= 99) {
        return const HealthRangeResult(
          status: 'Normal Fasting',
          description: 'Healthy fasting blood glucose level',
          color: AppColors.success,
          referenceInfo: 'Fasting normal: 70 - 99 mg/dL',
        );
      } else if (glucose <= 125) {
        return const HealthRangeResult(
          status: 'Pre-diabetes Range',
          description: 'Elevated fasting glucose level',
          color: AppColors.warning,
          referenceInfo: 'Pre-diabetes fasting: 100 - 125 mg/dL',
        );
      } else {
        return const HealthRangeResult(
          status: 'High Fasting',
          description: 'Above standard fasting threshold',
          color: AppColors.danger,
          referenceInfo: 'Elevated fasting: ≥ 126 mg/dL',
        );
      }
    } else {
      // Post-prandial / Random
      if (glucose < 140) {
        return const HealthRangeResult(
          status: 'Normal Post-Meal',
          description: 'Healthy post-meal blood sugar level',
          color: AppColors.success,
          referenceInfo: 'Post-meal normal: < 140 mg/dL',
        );
      } else if (glucose <= 199) {
        return const HealthRangeResult(
          status: 'Elevated Post-Meal',
          description: 'Higher than usual post-meal sugar',
          color: AppColors.warning,
          referenceInfo: 'Post-meal elevated: 140 - 199 mg/dL',
        );
      } else {
        return const HealthRangeResult(
          status: 'High Post-Meal',
          description: 'Markedly high post-meal reading',
          color: AppColors.danger,
          referenceInfo: 'Post-meal high: ≥ 200 mg/dL',
        );
      }
    }
  }

  // Heart Rate Evaluation (BPM)
  static HealthRangeResult evaluateHeartRate(double bpm) {
    if (bpm < 60) {
      return const HealthRangeResult(
        status: 'Low (Bradycardia)',
        description: 'Resting rate below standard 60 bpm',
        color: AppColors.info,
        referenceInfo: 'Typical resting rate: 60 - 100 bpm',
      );
    } else if (bpm <= 100) {
      return const HealthRangeResult(
        status: 'Normal',
        description: 'Standard healthy resting heart rate',
        color: AppColors.success,
        referenceInfo: 'Typical resting rate: 60 - 100 bpm',
      );
    } else {
      return const HealthRangeResult(
        status: 'High (Tachycardia)',
        description: 'Elevated resting pulse',
        color: AppColors.danger,
        referenceInfo: 'Typical resting rate: 60 - 100 bpm',
      );
    }
  }

  // Body Temperature Evaluation (Celsius)
  static HealthRangeResult evaluateBodyTemperature(double celsius) {
    if (celsius < 35.0) {
      return const HealthRangeResult(
        status: 'Hypothermia',
        description: 'Abnormally low body temperature',
        color: AppColors.info,
        referenceInfo: 'Normal range: 36.5°C - 37.5°C (97.7°F - 99.5°F)',
      );
    } else if (celsius <= 37.5) {
      return const HealthRangeResult(
        status: 'Normal',
        description: 'Healthy core temperature',
        color: AppColors.success,
        referenceInfo: 'Normal range: 36.5°C - 37.5°C (97.7°F - 99.5°F)',
      );
    } else if (celsius <= 38.3) {
      return const HealthRangeResult(
        status: 'Mild Fever',
        description: 'Slightly elevated temperature',
        color: AppColors.warning,
        referenceInfo: 'Fever threshold: ≥ 38.0°C (100.4°F)',
      );
    } else {
      return const HealthRangeResult(
        status: 'High Fever',
        description: 'Significant fever detected',
        color: AppColors.danger,
        referenceInfo: 'High fever: ≥ 38.4°C (101.1°F)',
      );
    }
  }

  // Oxygen Saturation SpO2 (%)
  static HealthRangeResult evaluateSpO2(double spo2) {
    if (spo2 >= 95) {
      return const HealthRangeResult(
        status: 'Normal',
        description: 'Optimal blood oxygen saturation',
        color: AppColors.success,
        referenceInfo: 'Standard normal: 95% - 100%',
      );
    } else if (spo2 >= 90) {
      return const HealthRangeResult(
        status: 'Mild Hypoxia',
        description: 'Below normal oxygen level',
        color: AppColors.warning,
        referenceInfo: 'Borderline range: 90% - 94%',
      );
    } else {
      return const HealthRangeResult(
        status: 'Critical Hypoxia',
        description: 'Significantly low oxygen saturation',
        color: AppColors.danger,
        referenceInfo: 'Critical range: < 90%',
      );
    }
  }

  // BMI Calculation & Evaluation
  static double calculateBMI(double weightKg, double heightCm) {
    if (heightCm <= 0) return 0;
    final heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  static HealthRangeResult evaluateBMI(double bmi) {
    if (bmi < 18.5) {
      return const HealthRangeResult(
        status: 'Underweight',
        description: 'BMI below standard healthy range',
        color: AppColors.info,
        referenceInfo: 'Normal BMI: 18.5 - 24.9',
      );
    } else if (bmi <= 24.9) {
      return const HealthRangeResult(
        status: 'Normal Weight',
        description: 'Healthy body mass index',
        color: AppColors.success,
        referenceInfo: 'Normal BMI: 18.5 - 24.9',
      );
    } else if (bmi <= 29.9) {
      return const HealthRangeResult(
        status: 'Overweight',
        description: 'BMI above normal range',
        color: AppColors.warning,
        referenceInfo: 'Overweight: 25.0 - 29.9',
      );
    } else {
      return const HealthRangeResult(
        status: 'Obesity',
        description: 'BMI indicates obesity',
        color: AppColors.danger,
        referenceInfo: 'Obesity: ≥ 30.0',
      );
    }
  }
}
