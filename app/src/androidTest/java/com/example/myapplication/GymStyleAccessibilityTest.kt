package com.example.myapplication

import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.unit.dp
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.myapplication.ui.theme.EnergyOrange
import com.example.myapplication.ui.theme.GymAppTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class GymStyleAccessibilityTest {
    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun primaryAction_hasCorrectTouchTargetSize() {
        composeTestRule.setContent {
            GymAppTheme {
                Button(
                    onClick = {},
                    colors = ButtonDefaults.buttonColors(containerColor = EnergyOrange),
                    modifier = Modifier
                        .width(200.dp)
                        .height(48.dp) // Minimum 48dp height for touch target
                        .testTag("action-btn")
                ) {
                    Text("BẮT ĐẦU TẬP")
                }
            }
        }

        composeTestRule.onNodeWithTag("action-btn").assertHeightIsEqualTo(48.dp)
        composeTestRule.onNodeWithTag("action-btn").assertIsEnabled()
    }

    @Test
    fun disabledPrimaryAction_isNotEnabled() {
        composeTestRule.setContent {
            GymAppTheme {
                Button(
                    onClick = {},
                    enabled = false,
                    modifier = Modifier.testTag("disabled-btn")
                ) {
                    Text("ĐÃ HOÀN THÀNH")
                }
            }
        }

        composeTestRule.onNodeWithTag("disabled-btn").assertIsNotEnabled()
    }
}
