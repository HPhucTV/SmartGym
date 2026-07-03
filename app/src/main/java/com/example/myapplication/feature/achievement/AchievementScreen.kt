package com.example.myapplication.feature.achievement

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.myapplication.core.achievement.AchievementType
import com.example.myapplication.data.local.AchievementEntity
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

private object AchievementPalette {
    val navy = Color(0xFF14213D)
    val orange = Color(0xFFF97316)
    val green = Color(0xFF22C55E)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AchievementScreen(
    unlockedList: List<AchievementEntity>,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val unlockedMap = remember(unlockedList) { unlockedList.associateBy { it.type } }
    var selectedBadge by remember { mutableStateOf<AchievementType?>(null) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        "Thành Tựu & Huy Hiệu 🏆",
                        color = MaterialTheme.colorScheme.onBackground,
                        fontWeight = FontWeight.Bold,
                        fontSize = 20.sp
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Text("←", fontSize = 24.sp, color = MaterialTheme.colorScheme.onBackground)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.background)
            )
        },
        containerColor = MaterialTheme.colorScheme.background,
        modifier = modifier
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 16.dp)
        ) {
            // Summary Card
            Card(
                colors = CardDefaults.cardColors(containerColor = AchievementPalette.navy),
                shape = RoundedCornerShape(16.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 12.dp)
            ) {
                Row(
                    modifier = Modifier.padding(20.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            "Danh Hiệu Chiến Binh",
                            color = Color.White,
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            "Đã mở khóa ${unlockedList.size} / ${AchievementType.values().size} huy hiệu",
                            color = Color(0xFF94A3B8),
                            fontSize = 14.sp
                        )
                    }
                    Text(
                        text = "${((unlockedList.size * 100L) / AchievementType.values().size.coerceAtLeast(1))}%",
                        color = AchievementPalette.orange,
                        fontSize = 36.sp,
                        fontWeight = FontWeight.Black
                    )
                }
            }

            Text(
                "TỦ HUY HIỆU CỦA BẠN",
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.2.sp,
                modifier = Modifier.padding(vertical = 8.dp)
            )

            // Grid of Badges
            LazyVerticalGrid(
                columns = GridCells.Fixed(3),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.weight(1f)
            ) {
                items(AchievementType.values()) { badge ->
                    val unlockInfo = unlockedMap[badge.name]
                    val isUnlocked = unlockInfo != null
                    BadgeItem(
                        badge = badge,
                        isUnlocked = isUnlocked,
                        onClick = { selectedBadge = badge }
                    )
                }
            }
        }
    }

    // Badge Details BottomSheet / Dialog
    selectedBadge?.let { badge ->
        val unlockInfo = unlockedMap[badge.name]
        val isUnlocked = unlockInfo != null
        BadgeDetailDialog(
            badge = badge,
            unlockInfo = unlockInfo,
            isUnlocked = isUnlocked,
            onDismiss = { selectedBadge = null }
        )
    }
}

@Composable
private fun BadgeItem(
    badge: AchievementType,
    isUnlocked: Boolean,
    onClick: () -> Unit
) {
    Surface(
        color = if (isUnlocked) MaterialTheme.colorScheme.surfaceVariant else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
        shape = RoundedCornerShape(16.dp),
        border = androidx.compose.foundation.BorderStroke(
            width = 1.dp,
            color = if (isUnlocked) AchievementPalette.orange else MaterialTheme.colorScheme.outline
        ),
        modifier = Modifier
            .aspectRatio(1f)
            .clickable(onClick = onClick)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.padding(8.dp)
        ) {
            Text(
                text = badge.icon,
                fontSize = 32.sp,
                modifier = Modifier.alpha(if (isUnlocked) 1f else 0.25f)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = badge.titleVi,
                color = if (isUnlocked) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                maxLines = 2
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun BadgeDetailDialog(
    badge: AchievementType,
    unlockInfo: AchievementEntity?,
    isUnlocked: Boolean,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                if (isUnlocked) {
                    val context = androidx.compose.ui.platform.LocalContext.current
                    OutlinedButton(
                        onClick = {
                            val shareText = """
                                🏆 THÀNH TỰU MỚI TỪ SMARTGYM 🏆
                                🥇 Tôi vừa mở khóa huy hiệu: ${badge.icon} ${badge.titleVi}!
                                🎯 Mô tả: ${badge.descriptionVi}
                                🔥 Tập luyện thông minh, offline-first cùng SmartGym!
                            """.trimIndent()
                            val sendIntent = android.content.Intent().apply {
                                action = android.content.Intent.ACTION_SEND
                                putExtra(android.content.Intent.EXTRA_TEXT, shareText)
                                type = "text/plain"
                            }
                            val shareIntent = android.content.Intent.createChooser(sendIntent, "Chia sẻ huy hiệu")
                            context.startActivity(shareIntent)
                        },
                        shape = RoundedCornerShape(12.dp),
                        border = androidx.compose.foundation.BorderStroke(1.dp, AchievementPalette.orange),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = AchievementPalette.orange)
                    ) {
                        Text("Chia sẻ 🔗", fontWeight = FontWeight.Bold)
                    }
                }
                Button(
                    onClick = onDismiss,
                    colors = ButtonDefaults.buttonColors(containerColor = AchievementPalette.orange),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text("Đóng", fontWeight = FontWeight.Bold, color = Color.White)
                }
            }
        },
        title = {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(badge.icon, fontSize = 56.sp)
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = badge.titleVi,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center
                )
            }
        },
        text = {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = badge.descriptionVi,
                    color = MaterialTheme.colorScheme.onSurface,
                    style = MaterialTheme.typography.bodyLarge,
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(16.dp))
                if (isUnlocked && unlockInfo != null) {
                    val dateStr = remember(unlockInfo.unlockedAtEpochMillis) {
                        val instant = Instant.ofEpochMilli(unlockInfo.unlockedAtEpochMillis)
                        val formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")
                            .withZone(ZoneId.systemDefault())
                        formatter.format(instant)
                    }
                    Text(
                        text = "🔓 Đã mở khóa vào:\n$dateStr",
                        color = AchievementPalette.green,
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        textAlign = TextAlign.Center
                    )
                } else {
                    Text(
                        text = "🔒 Chưa mở khóa",
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        },
        shape = RoundedCornerShape(20.dp),
        containerColor = MaterialTheme.colorScheme.surface
    )
}
