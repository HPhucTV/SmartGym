package com.example.myapplication.core.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.layout.onGloballyPositioned
import kotlin.random.Random

private data class ConfettiParticle(
    var x: Float,
    var y: Float,
    val color: Color,
    val size: Float,
    var vx: Float,
    var vy: Float,
    var rotation: Float,
    val rotationSpeed: Float,
    val shape: ParticleShape,
)

private enum class ParticleShape {
    RECTANGLE, CIRCLE, TRIANGLE
}

@Composable
fun ConfettiCelebration(
    isActive: Boolean,
    modifier: Modifier = Modifier,
    durationMillis: Long = 3000L,
    onFinished: () -> Unit = {}
) {
    if (!isActive) return

    var width by remember { mutableFloatStateOf(0f) }
    var height by remember { mutableFloatStateOf(0f) }
    val particles = remember { mutableStateListOf<ConfettiParticle>() }
    var animationFrameNanos by remember { mutableLongStateOf(0L) }

    // Colors: Vibrant Orange, Green, Blue, Yellow, Pink
    val colors = remember {
        listOf(
            Color(0xFFF97316), // Orange
            Color(0xFF22C55E), // Green
            Color(0xFF3B82F6), // Blue
            Color(0xFFEAB308), // Yellow
            Color(0xFFEC4899), // Pink
            Color(0xFF8B5CF6)  // Purple
        )
    }

    // Initialize particles once sizes are known
    LaunchedEffect(isActive, width, height) {
        if (width > 0f && height > 0f && particles.isEmpty()) {
            val random = Random(System.currentTimeMillis())
            repeat(120) {
                // Spawn from bottom/center or edges slightly
                val startX = width * random.nextFloat()
                val startY = height * 0.1f // spawn near top
                val speedAngle = random.nextFloat() * Math.PI.toFloat() * 2f
                val speedMag = 5f + random.nextFloat() * 15f
                val shape = ParticleShape.values()[random.nextInt(ParticleShape.values().size)]

                particles.add(
                    ConfettiParticle(
                        x = startX,
                        y = startY,
                        color = colors[random.nextInt(colors.size)],
                        size = 12f + random.nextFloat() * 16f,
                        vx = (Math.cos(speedAngle.toDouble()).toFloat() * speedMag),
                        vy = 12f + random.nextFloat() * 20f, // fall speed
                        rotation = random.nextFloat() * 360f,
                        rotationSpeed = -5f + random.nextFloat() * 10f,
                        shape = shape
                    )
                )
            }
        }
    }

    // Animation Loop
    LaunchedEffect(isActive) {
        val startTimeNanos = withFrameNanos { it }
        var elapsedMillis = 0L
        while (elapsedMillis < durationMillis) {
            withFrameNanos { frameTimeNanos ->
                val gravity = 0.5f
                particles.forEach { p ->
                    p.x += p.vx
                    p.y += p.vy
                    p.vy += gravity
                    p.vx *= 0.98f // wind resistance
                    p.rotation += p.rotationSpeed
                }
                animationFrameNanos = frameTimeNanos
                elapsedMillis = (frameTimeNanos - startTimeNanos) / 1_000_000L
            }
        }
        particles.clear()
        onFinished()
    }

    Canvas(
        modifier = modifier
            .fillMaxSize()
            .onGloballyPositioned { coordinates ->
                width = coordinates.size.width.toFloat()
                height = coordinates.size.height.toFloat()
            }
    ) {
        // Reading frame state in the draw scope invalidates Canvas after particle mutation.
        if (animationFrameNanos == Long.MIN_VALUE) return@Canvas
        particles.forEach { p ->
            withTransform({
                rotate(p.rotation, Offset(p.x, p.y))
            }) {
                when (p.shape) {
                    ParticleShape.RECTANGLE -> {
                        drawRect(
                            color = p.color,
                            topLeft = Offset(p.x - p.size / 2, p.y - p.size / 4),
                            size = Size(p.size, p.size / 2)
                        )
                    }
                    ParticleShape.CIRCLE -> {
                        drawCircle(
                            color = p.color,
                            center = Offset(p.x, p.y),
                            radius = p.size / 2
                        )
                    }
                    ParticleShape.TRIANGLE -> {
                        // Drawing simple triangle
                        val path = androidx.compose.ui.graphics.Path().apply {
                            moveTo(p.x, p.y - p.size / 2)
                            lineTo(p.x - p.size / 2, p.y + p.size / 2)
                            lineTo(p.x + p.size / 2, p.y + p.size / 2)
                            close()
                        }
                        drawPath(path = path, color = p.color)
                    }
                }
            }
        }
    }
}
