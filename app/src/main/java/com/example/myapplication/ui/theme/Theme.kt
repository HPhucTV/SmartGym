package com.example.myapplication.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

@Immutable
data class GymCustomColors(
    val orangeLight: Color,
    val greenLight: Color,
    val checkedCardBorder: Color,
    val recoveryBlue: Color,
    val recoveryBlueBg: Color,
    val primaryText: Color,
    val mutedText: Color,
)

val LightGymCustomColors = GymCustomColors(
    orangeLight = OrangeLight,
    greenLight = GreenLight,
    checkedCardBorder = CheckedCardBorder,
    recoveryBlue = RecoveryBlue,
    recoveryBlueBg = RecoveryBlueBg,
    primaryText = Navy,
    mutedText = MutedText,
)

val DarkGymCustomColors = GymCustomColors(
    orangeLight = DarkOrangeLight,
    greenLight = DarkGreenLight,
    checkedCardBorder = DarkCheckedCardBorder,
    recoveryBlue = DarkRecoveryBlue,
    recoveryBlueBg = DarkRecoveryBlueBg,
    primaryText = DarkText,
    mutedText = DarkMutedText,
)

val LocalGymCustomColors = staticCompositionLocalOf { LightGymCustomColors }

val ColorScheme.customColors: GymCustomColors
    @Composable
    get() = LocalGymCustomColors.current

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

private val GymDarkColorScheme = darkColorScheme(
    primary = EnergyOrange,
    onPrimary = White,
    secondary = SuccessGreen,
    onSecondary = DarkBg,
    background = DarkBg,
    onBackground = DarkText,
    surface = DarkSurface,
    onSurface = DarkText,
    surfaceVariant = DarkSurfaceVariant,
    onSurfaceVariant = DarkMutedText,
    outline = DarkBorder,
)

@Composable
fun GymAppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colorScheme = if (darkTheme) GymDarkColorScheme else GymLightColorScheme
    val customColors = if (darkTheme) DarkGymCustomColors else LightGymCustomColors

    CompositionLocalProvider(LocalGymCustomColors provides customColors) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography = GymTypography,
            content = content,
        )
    }
}
