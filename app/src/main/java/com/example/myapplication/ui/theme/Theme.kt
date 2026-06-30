package com.example.myapplication.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val GymLightColorScheme = lightColorScheme(
    primary = EnergyOrange,
    onPrimary = White,
    secondary = SuccessGreen,
    onSecondary = Navy,
    background = White,
    onBackground = Navy,
    surface = White,
    onSurface = Navy,
    surfaceVariant = SurfaceGray,
    onSurfaceVariant = MutedText,
    outline = BorderGray,
)

@Composable
fun GymAppTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = GymLightColorScheme,
        typography = GymTypography,
        content = content,
    )
}
