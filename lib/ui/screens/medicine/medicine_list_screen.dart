import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/medicine_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/medicine_provider.dart';
import 'add_edit_medicine_screen.dart';
import 'medicine_detail_screen.dart';

class MedicineListScreen extends StatelessWidget {
  const MedicineListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final medProvider = Provider.of<MedicineProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final medicines = medProvider.medicines;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('My Medicines'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Medicine',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditMedicineScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => medProvider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search medicines by name or type...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: medProvider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => medProvider.setSearchQuery(''),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        context,
                        label: 'All (${medProvider.allMedicines.length})',
                        selected: medProvider.currentFilter == MedicineFilter.all,
                        onTap: () => medProvider.setFilter(MedicineFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: 'Active (${medProvider.allMedicines.where((m) => m.isActive).length})',
                        selected: medProvider.currentFilter == MedicineFilter.active,
                        onTap: () => medProvider.setFilter(MedicineFilter.active),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: 'Completed (${medProvider.allMedicines.where((m) => !m.isActive).length})',
                        selected: medProvider.currentFilter == MedicineFilter.completed,
                        onTap: () => medProvider.setFilter(MedicineFilter.completed),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: 'Low Stock (${medProvider.lowStockCount})',
                        selected: medProvider.currentFilter == MedicineFilter.lowStock,
                        color: AppColors.warning,
                        onTap: () => medProvider.setFilter(MedicineFilter.lowStock),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List of Medicines
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final userId = authProvider.currentUser?.id;
                if (userId != null) {
                  await medProvider.loadMedicines(userId);
                }
              },
              child: medicines.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 64,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            medProvider.searchQuery.isNotEmpty
                                ? 'No medicines matching "${medProvider.searchQuery}"'
                                : 'No medicines found',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the "+" button above to add your first medicine',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: medicines.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final medicine = medicines[index];
                        return _buildMedicineCard(context, medicine, isDark);
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditMedicineScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Medicine'),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color color = AppColors.primary,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withValues(alpha: 0.18),
      checkmarkColor: color,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        color: selected ? color : null,
      ),
    );
  }

  Widget _buildMedicineCard(BuildContext context, MedicineModel med, bool isDark) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MedicineDetailScreen(medicine: med)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getIconForType(med.medicineType),
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                med.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: med.isActive
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : Colors.grey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                med.isActive ? 'Active' : 'Completed',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: med.isActive ? AppColors.success : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${med.medicineType} • ${med.dosage} • ${med.frequency}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${med.foodTiming} | ${med.startDate} to ${med.endDate}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              // Stock & Schedule Information
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        med.isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                        size: 16,
                        color: med.isLowStock ? AppColors.danger : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Stock: ${med.remainingStock} / ${med.totalStock}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: med.isLowStock ? AppColors.danger : null,
                        ),
                      ),
                      if (med.isLowStock) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'LOW',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.danger),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${med.schedules.length} reminder(s) daily',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'tablet':
      case 'capsule':
        return Icons.medication_rounded;
      case 'syrup':
        return Icons.water_drop_rounded;
      case 'injection':
        return Icons.vaccines_rounded;
      case 'inhaler':
        return Icons.air_rounded;
      case 'drops':
        return Icons.opacity_rounded;
      default:
        return Icons.healing_rounded;
    }
  }
}
