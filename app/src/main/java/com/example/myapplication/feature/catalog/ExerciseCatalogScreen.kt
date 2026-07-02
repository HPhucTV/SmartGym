package com.example.myapplication.feature.catalog

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.core.model.Equipment
import com.example.myapplication.core.model.ExerciseDefinition
import com.example.myapplication.core.model.MuscleGroup
import com.example.myapplication.ui.theme.EnergyOrange
import com.example.myapplication.ui.theme.SuccessGreen
import com.example.myapplication.ui.theme.customColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExerciseCatalogScreen(
    exercises: List<ExerciseDefinition>,
    onBack: (() -> Unit)? = null,
) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors

    var searchQuery by remember { mutableStateOf("") }
    var selectedMuscle by remember { mutableStateOf<MuscleGroup?>(null) }
    var selectedEquipment by remember { mutableStateOf<Equipment?>(null) }

    val filteredExercises = remember(searchQuery, selectedMuscle, selectedEquipment, exercises) {
        exercises.filter { exercise ->
            val matchesSearch = exercise.nameVi.contains(searchQuery, ignoreCase = true) ||
                    exercise.instructionsVi.any { it.contains(searchQuery, ignoreCase = true) }
            val matchesMuscle = selectedMuscle == null || exercise.primaryMuscle == selectedMuscle || exercise.secondaryMuscles.contains(selectedMuscle)
            val matchesEquipment = selectedEquipment == null || exercise.equipment.contains(selectedEquipment)
            matchesSearch && matchesMuscle && matchesEquipment
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Thư viện bài tập 📚", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    if (onBack != null) {
                        TextButton(onClick = onBack) {
                            Text("◀", color = EnergyOrange, fontSize = 20.sp)
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = colors.background,
                    titleContentColor = customColors.primaryText,
                    navigationIconContentColor = customColors.primaryText
                )
            )
        },
        containerColor = colors.background
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Search Bar
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                placeholder = { Text("Tìm kiếm tên bài tập, hướng dẫn...") },
                singleLine = true,
                shape = RoundedCornerShape(14.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = EnergyOrange,
                    unfocusedBorderColor = colors.outline
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 8.dp)
            )

            // Muscle filters
            Text(
                "Nhóm cơ tập trung",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = customColors.primaryText,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 4.dp)
            )
            LazyRow(
                contentPadding = PaddingValues(horizontal = 20.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)
            ) {
                item {
                    FilterChip(
                        selected = selectedMuscle == null,
                        onClick = { selectedMuscle = null },
                        label = { Text("Tất cả") }
                    )
                }
                items(MuscleGroup.entries) { muscle ->
                    FilterChip(
                        selected = selectedMuscle == muscle,
                        onClick = { selectedMuscle = muscle },
                        label = { Text(muscleLabelVi(muscle)) }
                    )
                }
            }

            // Equipment filters
            Text(
                "Dụng cụ cần thiết",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = customColors.primaryText,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 4.dp)
            )
            LazyRow(
                contentPadding = PaddingValues(horizontal = 20.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)
            ) {
                item {
                    FilterChip(
                        selected = selectedEquipment == null,
                        onClick = { selectedEquipment = null },
                        label = { Text("Tất cả") }
                    )
                }
                items(Equipment.entries) { equipment ->
                    FilterChip(
                        selected = selectedEquipment == equipment,
                        onClick = { selectedEquipment = equipment },
                        label = { Text(equipmentLabelVi(equipment)) }
                    )
                }
            }

            // Results List
            LazyColumn(
                contentPadding = PaddingValues(horizontal = 20.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.weight(1f).fillMaxWidth()
            ) {
                if (filteredExercises.isEmpty()) {
                    item {
                        Box(
                            modifier = Modifier.fillParentMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            Text("Không tìm thấy bài tập nào phù hợp 🔍", color = customColors.mutedText)
                        }
                    }
                } else {
                    items(filteredExercises, key = { it.id }) { exercise ->
                        CatalogExerciseCard(exercise)
                    }
                }
            }
        }
    }
}

@Composable
private fun CatalogExerciseCard(exercise: ExerciseDefinition) {
    val colors = MaterialTheme.colorScheme
    val customColors = colors.customColors
    var expanded by remember { mutableStateOf(false) }

    Column(
        Modifier
            .fillMaxWidth()
            .animateContentSize()
            .background(colors.surfaceVariant, RoundedCornerShape(16.dp))
            .border(1.dp, colors.outline, RoundedCornerShape(16.dp))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(EnergyOrange),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    muscleEmoji(exercise.primaryMuscle),
                    fontSize = 18.sp
                )
            }
            Spacer(Modifier.width(12.dp))

            Column(Modifier.weight(1f)) {
                Text(
                    exercise.nameVi,
                    style = MaterialTheme.typography.titleMedium,
                    color = customColors.primaryText,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    "${muscleLabelVi(exercise.primaryMuscle)} · ${exercise.equipment.joinToString { equipmentLabelVi(it) }}",
                    color = customColors.mutedText,
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }

        // Expandable instructions
        Text(
            if (expanded) "Ẩn hướng dẫn ▲" else "Xem hướng dẫn ▼",
            color = EnergyOrange,
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier
                .fillMaxWidth()
                .clickable { expanded = !expanded }
                .padding(vertical = 4.dp),
        )

        if (expanded) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .background(colors.surface, RoundedCornerShape(12.dp))
                    .padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                exercise.instructionsVi.forEachIndexed { index, instruction ->
                    Row {
                        Text(
                            "${index + 1}.",
                            color = EnergyOrange,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.width(24.dp)
                        )
                        Text(instruction, color = customColors.primaryText, style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
        }
    }
}

private fun muscleLabelVi(muscle: MuscleGroup): String = when (muscle) {
    MuscleGroup.CHEST -> "Ngực"
    MuscleGroup.BACK -> "Lưng"
    MuscleGroup.SHOULDERS -> "Vai"
    MuscleGroup.BICEPS -> "Tay trước"
    MuscleGroup.TRICEPS -> "Tay sau"
    MuscleGroup.CORE -> "Bụng"
    MuscleGroup.QUADS -> "Đùi trước"
    MuscleGroup.HAMSTRINGS -> "Đùi sau"
    MuscleGroup.GLUTES -> "Mông"
    MuscleGroup.CALVES -> "Bắp chân"
    MuscleGroup.FULL_BODY -> "Toàn thân"
    MuscleGroup.CARDIO -> "Tim mạch"
    MuscleGroup.MOBILITY -> "Di động"
}

private fun equipmentLabelVi(eq: Equipment): String = when (eq) {
    Equipment.BODYWEIGHT -> "Không dụng cụ"
    Equipment.DUMBBELL -> "Tạ đơn"
    Equipment.BAND -> "Dây kháng lực"
    Equipment.BARBELL -> "Tạ đòn"
    Equipment.BENCH -> "Ghế băng"
    Equipment.CABLE -> "Cáp"
    Equipment.MACHINE -> "Máy tập"
    Equipment.CARDIO_MACHINE -> "Máy chạy/đạp xe"
}

private fun muscleEmoji(muscle: MuscleGroup): String = when (muscle) {
    MuscleGroup.CHEST -> "🫁"
    MuscleGroup.BACK -> "🔙"
    MuscleGroup.SHOULDERS -> "💪"
    MuscleGroup.BICEPS -> "💪"
    MuscleGroup.TRICEPS -> "💪"
    MuscleGroup.CORE -> "🎯"
    MuscleGroup.QUADS -> "🦵"
    MuscleGroup.HAMSTRINGS -> "🦵"
    MuscleGroup.GLUTES -> "🍑"
    MuscleGroup.CALVES -> "🦶"
    MuscleGroup.FULL_BODY -> "🏋️"
    MuscleGroup.CARDIO -> "❤️"
    MuscleGroup.MOBILITY -> "🧘"
}
