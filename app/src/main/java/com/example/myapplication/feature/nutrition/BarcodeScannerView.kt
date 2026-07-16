package com.example.myapplication.feature.nutrition

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.example.myapplication.ui.theme.EnergyOrange
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
import java.time.LocalTime

/**
 * Full-screen CameraX preview with ML Kit barcode analysis. Calls [onBarcodeDetected] with the
 * first detected barcode value (and vibrates the device), then lets the caller dismiss via
 * [onClose].
 */
@Composable
fun BarcodeScannerView(
    onBarcodeDetected: (String) -> Unit,
    onClose: () -> Unit,
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val cameraProviderFuture = remember { ProcessCameraProvider.getInstance(context) }

    DisposableEffect(lifecycleOwner) {
        onDispose {
            try {
                if (cameraProviderFuture.isDone) {
                    val cameraProvider = cameraProviderFuture.get()
                    cameraProvider.unbindAll()
                }
            } catch (e: Exception) {
                Log.e("BarcodeScannerView", "Error unbinding camera on dispose", e)
            }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        AndroidView(
            factory = { ctx ->
                val previewView = PreviewView(ctx).apply {
                    scaleType = PreviewView.ScaleType.FILL_CENTER
                }
                val executor = ContextCompat.getMainExecutor(ctx)
                cameraProviderFuture.addListener({
                    val cameraProvider = cameraProviderFuture.get()
                    val preview = Preview.Builder().build().also {
                        it.surfaceProvider = previewView.surfaceProvider
                    }

                    val barcodeScanner = BarcodeScanning.getClient()

                    val imageAnalysis = ImageAnalysis.Builder()
                        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                        .build()

                    imageAnalysis.setAnalyzer(executor) { imageProxy ->
                        @OptIn(ExperimentalGetImage::class)
                        val mediaImage = imageProxy.image
                        if (mediaImage != null) {
                            val image = InputImage.fromMediaImage(
                                mediaImage,
                                imageProxy.imageInfo.rotationDegrees
                            )
                            barcodeScanner.process(image)
                                .addOnSuccessListener { barcodes ->
                                    for (barcode in barcodes) {
                                        val rawValue = barcode.rawValue
                                        if (!rawValue.isNullOrBlank()) {
                                            try {
                                                vibrateOnce(ctx)
                                            } catch (_: Exception) {
                                            }
                                            onBarcodeDetected(rawValue)
                                            break
                                        }
                                    }
                                }
                                .addOnCompleteListener {
                                    imageProxy.close()
                                }
                        } else {
                            imageProxy.close()
                        }
                    }

                    val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

                    try {
                        cameraProvider.unbindAll()
                        cameraProvider.bindToLifecycle(
                            lifecycleOwner,
                            cameraSelector,
                            preview,
                            imageAnalysis
                        )
                    } catch (exc: Exception) {
                        Log.e("BarcodeScannerView", "Use case binding failed", exc)
                    }
                }, executor)
                previewView
            },
            modifier = Modifier.fillMaxSize()
        )

        Box(
            modifier = Modifier
                .size(width = 280.dp, height = 150.dp)
                .align(Alignment.Center)
                .background(Color.Transparent)
                .border(2.dp, EnergyOrange, RoundedCornerShape(12.dp))
        )

        Text(
            text = "Đặt mã vạch vào khung hình để quét",
            color = Color.White,
            fontWeight = FontWeight.Bold,
            fontSize = 14.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 120.dp)
                .background(Color.Black.copy(alpha = 0.6f), RoundedCornerShape(8.dp))
                .padding(horizontal = 16.dp, vertical = 8.dp)
        )

        IconButton(
            onClick = onClose,
            modifier = Modifier
                .padding(top = 40.dp, start = 16.dp)
                .align(Alignment.TopStart)
                .size(48.dp)
                .background(Color.Black.copy(alpha = 0.5f), CircleShape)
        ) {
            Canvas(
                modifier = Modifier
                    .size(24.dp)
                    .padding(4.dp)
            ) {
                val strokeWidth = 2.5.dp.toPx()
                drawLine(
                    color = Color.White,
                    start = Offset(0f, 0f),
                    end = Offset(size.width, size.height),
                    strokeWidth = strokeWidth,
                    cap = StrokeCap.Round
                )
                drawLine(
                    color = Color.White,
                    start = Offset(0f, size.height),
                    end = Offset(size.width, 0f),
                    strokeWidth = strokeWidth,
                    cap = StrokeCap.Round
                )
            }
        }
    }
}

private fun vibrateOnce(context: Context) {
    val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as? android.os.Vibrator
        ?: return
    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
        vibrator.vibrate(android.os.VibrationEffect.createOneShot(100, android.os.VibrationEffect.DEFAULT_AMPLITUDE))
    } else {
        @Suppress("DEPRECATION")
        vibrator.vibrate(100)
    }
}

/** Picks the default meal slot (BREAKFAST/LUNCH/SNACK/DINNER) based on the current hour. */
internal fun defaultMealTime(): String {
    val hour = LocalTime.now().hour
    return when {
        hour < 10 -> "BREAKFAST"
        hour < 14 -> "LUNCH"
        hour < 17 -> "SNACK"
        else -> "DINNER"
    }
}

/** Resolves a human-readable file name from a content:// or file:// [uri]. */
internal fun getFileName(context: Context, uri: Uri): String? {
    var result: String? = null
    if (uri.scheme == "content") {
        val cursor = context.contentResolver.query(uri, null, null, null, null)
        try {
            if (cursor != null && cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (nameIndex != -1) {
                    result = cursor.getString(nameIndex)
                }
            }
        } finally {
            cursor?.close()
        }
    }
    if (result == null) {
        result = uri.path
        val cut = result?.lastIndexOf('/')
        if (cut != null && cut != -1) {
            result = result.substring(cut + 1)
        }
    }
    return result
}
