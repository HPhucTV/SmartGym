import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/model/catalog_models.dart';
import '../../data/providers/data_providers.dart';
import '../../ui/theme/colors.dart';
import '../../ui/theme/theme.dart';
import '../../ui/components/exercise_3d_dialog.dart';
import '../../ui/theme/radius.dart';
import '../../ui/theme/typography.dart';
import '../../ui/components/gym_card.dart';

extension EquipmentLabelVi on Equipment {
  String labelVi() {
    switch (this) {
      case Equipment.bodyweight:
        return "Không dụng cụ";
      case Equipment.dumbbell:
        return "Tạ đơn";
      case Equipment.band:
        return "Dây kháng lực";
      case Equipment.barbell:
        return "Tạ đòn";
      case Equipment.bench:
        return "Ghế băng";
      case Equipment.cable:
        return "Cáp";
      case Equipment.machine:
        return "Máy tập";
      case Equipment.cardioMachine:
        return "Máy chạy/đạp xe";
    }
  }
}

extension MuscleGroupEmoji on MuscleGroup {
  String emoji() {
    switch (this) {
      case MuscleGroup.chest:
        return "🫁";
      case MuscleGroup.back:
        return "🔙";
      case MuscleGroup.shoulders:
      case MuscleGroup.biceps:
      case MuscleGroup.triceps:
        return "💪";
      case MuscleGroup.core:
        return "🎯";
      case MuscleGroup.quads:
      case MuscleGroup.hamstrings:
        return "🦵";
      case MuscleGroup.glutes:
        return "🍑";
      case MuscleGroup.calves:
        return "🦶";
      case MuscleGroup.fullBody:
        return "🏋️";
      case MuscleGroup.cardio:
        return "❤️";
      case MuscleGroup.mobility:
        return "🧘";
    }
  }
}

class ExerciseCatalogScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const ExerciseCatalogScreen({super.key, required this.onBack});

  @override
  ConsumerState<ExerciseCatalogScreen> createState() =>
      _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends ConsumerState<ExerciseCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  MuscleGroup? _selectedMuscle;
  Equipment? _selectedEquipment;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogRepo = ref.watch(assetCatalogRepositoryProvider);
    final exercises = catalogRepo.exercises;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customColors = context.customColors;

    final filteredExercises = exercises.where((exercise) {
      final matchesSearch =
          exercise.nameVi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          exercise.instructionsVi.any(
            (ins) => ins.toLowerCase().contains(_searchQuery.toLowerCase()),
          );
      final matchesMuscle =
          _selectedMuscle == null ||
          exercise.primaryMuscleGroup == _selectedMuscle ||
          exercise.secondaryMuscleGroups.contains(_selectedMuscle);
      final matchesEquipment =
          _selectedEquipment == null ||
          exercise.equipment.contains(_selectedEquipment);
      return matchesSearch && matchesMuscle && matchesEquipment;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.white,
      appBar: AppBar(
        title: Text(
          "Thư viện bài tập 📚",
          style: TextStyle(
            color: customColors.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          key: const ValueKey("catalog-back-button"),
          icon: const Icon(Icons.arrow_back),
          color: customColors.primaryText,
          onPressed: widget.onBack,
        ),
        backgroundColor: isDark ? AppColors.darkBg : AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Tìm kiếm tên bài tập, hướng dẫn...",
                  hintStyle: TextStyle(
                    color: customColors.mutedText,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search, color: customColors.mutedText),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.surfaceGray,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.energyOrange,
                      width: 1.5,
                    ),
                  ),
                ),
                style: TextStyle(color: customColors.primaryText, fontSize: 14),
              ),
            ),

            // Muscle filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                "Nhóm cơ tập trung",
                style: TextStyle(
                  color: customColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip(
                    label: "Tất cả",
                    selected: _selectedMuscle == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedMuscle = null;
                      });
                    },
                    isDark: isDark,
                  ),
                  ...MuscleGroup.values.map((muscle) {
                    return _buildFilterChip(
                      label: muscle.labelVi(),
                      selected: _selectedMuscle == muscle,
                      onSelected: (_) {
                        setState(() {
                          _selectedMuscle = muscle;
                        });
                      },
                      isDark: isDark,
                    );
                  }),
                ],
              ),
            ),

            // Equipment filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                "Dụng cụ cần thiết",
                style: TextStyle(
                  color: customColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip(
                    label: "Tất cả",
                    selected: _selectedEquipment == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedEquipment = null;
                      });
                    },
                    isDark: isDark,
                  ),
                  ...Equipment.values.map((eq) {
                    return _buildFilterChip(
                      label: eq.labelVi(),
                      selected: _selectedEquipment == eq,
                      onSelected: (_) {
                        setState(() {
                          _selectedEquipment = eq;
                        });
                      },
                      isDark: isDark,
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Results List
            Expanded(
              child: filteredExercises.isEmpty
                  ? Center(
                      child: Text(
                        "Không tìm thấy bài tập nào phù hợp 🔍",
                        style: TextStyle(
                          color: customColors.mutedText,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      itemCount: filteredExercises.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CatalogExerciseCard(
                            exercise: filteredExercises[index],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (isDark ? AppColors.darkText : AppColors.navy),
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: selected,
        onSelected: onSelected,
        selectedColor: AppColors.energyOrange,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceGray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
        showCheckmark: false,
      ),
    );
  }
}

class _CatalogExerciseCard extends StatefulWidget {
  final ExerciseDefinition exercise;

  const _CatalogExerciseCard({required this.exercise});

  @override
  State<_CatalogExerciseCard> createState() => _CatalogExerciseCardState();
}

class _CatalogExerciseCardState extends State<_CatalogExerciseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customColors = context.customColors;

    return GymCard(
      variant: GymCardVariant.outlined,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.energyOrange,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.exercise.primaryMuscleGroup.emoji(),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.exercise.nameVi,
                      style: GymTypography.titleMedium.bold.copyWith(
                        color: customColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${widget.exercise.primaryMuscleGroup.labelVi()} · ${widget.exercise.equipment.map((e) => e.labelVi()).join(', ')}",
                      style: isDark
                          ? GymTypography.bodySmall.mutedDark
                          : GymTypography.bodySmall.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Expand/Collapse label
          InkWell(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    _expanded ? "Ẩn hướng dẫn ▲" : "Xem hướng dẫn ▼",
                    style: GymTypography.labelSmall.orange.bold,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.surfaceGray,
                borderRadius: GymRadius.mdBorder,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...widget.exercise.instructionsVi.asMap().entries.map((
                    entry,
                  ) {
                    final index = entry.key;
                    final instruction = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${index + 1}.",
                            style: GymTypography.bodyMedium.orange.bold,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              instruction,
                              style: GymTypography.bodyMedium.copyWith(
                                color: customColors.primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (widget.exercise.animationId != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        key: ValueKey("exercise-3d-btn-${widget.exercise.id}"),
                        onPressed: () {
                          Exercise3DDialog.show(
                            context: context,
                            animationId: widget.exercise.animationId!,
                            exerciseName: widget.exercise.nameVi,
                            instructions: widget.exercise.instructionsVi,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.energyOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          "Xem chuyển động 3D",
                          style: GymTypography.titleSmall.white.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
