package com.example.myapplication.feature.nutrition

import android.graphics.Bitmap
import java.io.ByteArrayOutputStream
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.int
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.put
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody

interface FoodAnalysisClient {
    suspend fun analyze(bitmap: Bitmap?): ScanResult?
    suspend fun scanBarcode(barcode: String): ScanResult?
    suspend fun registerBarcode(barcode: String, result: ScanResult): Boolean
}

class OkHttpFoodAnalysisClient(
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build(),
    private val endpointProvider: () -> String? = {
        com.example.myapplication.app.BackendConfig.baseUrl?.let { "$it/api/analyze-food" }
    },
) : FoodAnalysisClient {
    override suspend fun scanBarcode(barcode: String): ScanResult? = withContext(Dispatchers.IO) {
        val baseUrl = com.example.myapplication.app.BackendConfig.baseUrl ?: return@withContext null
        val url = "$baseUrl/api/scan-barcode?barcode=$barcode"

        val request = Request.Builder()
            .url(url)
            .get()
            .build()

        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                if (response.code == 404) {
                    return@withContext null
                }
                val errorBody = response.body?.string()
                throw java.io.IOException("HTTP error ${response.code}: $errorBody")
            }
            val bodyString = response.body?.string() ?: throw java.io.IOException("Phản hồi trống từ máy chủ")
            parseScanResult(bodyString)
        }
    }

    override suspend fun registerBarcode(barcode: String, result: ScanResult): Boolean = withContext(Dispatchers.IO) {
        val baseUrl = com.example.myapplication.app.BackendConfig.baseUrl ?: return@withContext false
        val url = "$baseUrl/api/register-barcode"

        val payload = buildJsonObject {
            put("barcode", barcode)
            put("dishName", result.dishName)
            put("totalCalories", result.totalCalories)
            put("proteinGrams", result.proteinGrams)
            put("carbsGrams", result.carbsGrams)
            put("fatGrams", result.fatGrams)
            put("advice", result.advice)
        }.toString()

        val requestBody = payload.toRequestBody("application/json".toMediaType())
        val request = Request.Builder()
            .url(url)
            .post(requestBody)
            .build()

        client.newCall(request).execute().use { response ->
            response.isSuccessful
        }
    }

    override suspend fun analyze(bitmap: Bitmap?): ScanResult? = withContext(Dispatchers.IO) {
        if (bitmap == null) return@withContext null
        val endpointUrl = endpointProvider() ?: return@withContext null

        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 85, stream)

        val requestBody = MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart(
                "image",
                "food.jpg",
                stream.toByteArray().toRequestBody("image/jpeg".toMediaType()),
            )
            .build()

        val request = Request.Builder()
            .url(endpointUrl)
            .post(requestBody)
            .build()

        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                val errorBody = response.body?.string()
                val serverErrorMessage = runCatching {
                    Json.parseToJsonElement(errorBody ?: "").jsonObject["error"]?.jsonPrimitive?.content
                }.getOrNull()
                throw java.io.IOException(serverErrorMessage ?: "Lỗi HTTP ${response.code}")
            }
            val bodyString = response.body?.string() ?: throw java.io.IOException("Phản hồi trống từ máy chủ")
            parseScanResult(bodyString)
        }
    }

    private fun parseScanResult(bodyString: String): ScanResult {
        val element = Json.parseToJsonElement(bodyString).jsonObject
        val sweatProposal = element["sweatPayment"]?.jsonObject?.let { proposal ->
            SweatPaymentProposal(
                exerciseId = proposal["exerciseId"]?.jsonPrimitive?.content ?: "bodyweight_squat",
                exerciseName = proposal["exerciseName"]?.jsonPrimitive?.content ?: "Squat khong ta",
                extraSets = proposal["extraSets"]?.jsonPrimitive?.int ?: 1,
            )
        }
        val constituents = element["components"]?.jsonArray?.map { item ->
            val obj = item.jsonObject
            Constituent(
                name = obj["name"]?.jsonPrimitive?.content ?: "",
                calories = obj["calories"]?.jsonPrimitive?.int ?: 0,
                protein = obj["protein"]?.jsonPrimitive?.int ?: 0,
                carbs = obj["carbs"]?.jsonPrimitive?.int ?: 0,
                fat = obj["fat"]?.jsonPrimitive?.int ?: 0,
            )
        } ?: emptyList()

        val rawConfidence = element["confidence"]?.jsonPrimitive?.doubleOrNull ?: 1.0
        val dishName = element["dishName"]?.jsonPrimitive?.content ?: "Mon an"
        val totalCalories = element["totalCalories"]?.jsonPrimitive?.int ?: 0
        val proteinGrams = element["proteinGrams"]?.jsonPrimitive?.int ?: 0
        val carbsGrams = element["carbsGrams"]?.jsonPrimitive?.int ?: 0
        val fatGrams = element["fatGrams"]?.jsonPrimitive?.int ?: 0

        val recommendations = element["recommendations"]?.jsonArray?.map { item ->
            val obj = item.jsonObject
            ScanRecommendation(
                dishName = obj["dishName"]?.jsonPrimitive?.content ?: "",
                confidence = obj["confidence"]?.jsonPrimitive?.doubleOrNull ?: 1.0,
                calories = obj["calories"]?.jsonPrimitive?.int ?: 0,
                proteinGrams = obj["proteinGrams"]?.jsonPrimitive?.int ?: 0,
                carbsGrams = obj["carbsGrams"]?.jsonPrimitive?.int ?: 0,
                fatGrams = obj["fatGrams"]?.jsonPrimitive?.int ?: 0
            )
        } ?: listOf(
            ScanRecommendation(dishName, rawConfidence, totalCalories, proteinGrams, carbsGrams, fatGrams),
            ScanRecommendation("$dishName (Tùy chọn 2)", (rawConfidence * 0.75).coerceAtLeast(0.1), (totalCalories * 1.1).toInt(), (proteinGrams * 1.1).toInt(), (carbsGrams * 1.1).toInt(), (fatGrams * 1.1).toInt()),
            ScanRecommendation("$dishName (Tùy chọn 3)", (rawConfidence * 0.50).coerceAtLeast(0.05), (totalCalories * 0.9).toInt(), (proteinGrams * 0.9).toInt(), (carbsGrams * 0.9).toInt(), (fatGrams * 0.9).toInt())
        )

        return ScanResult(
            dishName = dishName,
            totalCalories = totalCalories,
            proteinGrams = proteinGrams,
            carbsGrams = carbsGrams,
            fatGrams = fatGrams,
            fitnessScore = element["fitnessScore"]?.jsonPrimitive?.int ?: 5,
            advice = element["advice"]?.jsonPrimitive?.content ?: "",
            constituents = constituents,
            sweatPayment = sweatProposal,
            calculationProcess = element["calculationProcess"]?.jsonPrimitive?.content,
            confidence = rawConfidence,
            needsUserConfirmation = element["needsUserConfirmation"]?.jsonPrimitive?.booleanOrNull ?: false,
            recommendations = recommendations,
        )
    }

}
