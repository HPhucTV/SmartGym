package com.example.myapplication.feature.nutrition

import android.graphics.Bitmap
import java.io.ByteArrayOutputStream
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.int
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody

interface FoodAnalysisClient {
    suspend fun analyze(bitmap: Bitmap?): ScanResult?
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

        return ScanResult(
            dishName = element["dishName"]?.jsonPrimitive?.content ?: "Mon an",
            totalCalories = element["totalCalories"]?.jsonPrimitive?.int ?: 0,
            proteinGrams = element["proteinGrams"]?.jsonPrimitive?.int ?: 0,
            carbsGrams = element["carbsGrams"]?.jsonPrimitive?.int ?: 0,
            fatGrams = element["fatGrams"]?.jsonPrimitive?.int ?: 0,
            fitnessScore = element["fitnessScore"]?.jsonPrimitive?.int ?: 5,
            advice = element["advice"]?.jsonPrimitive?.content ?: "",
            constituents = constituents,
            sweatPayment = sweatProposal,
        )
    }
}
