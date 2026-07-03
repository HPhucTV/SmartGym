package com.example.myapplication.data

import com.example.myapplication.app.BackendConfig
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody

data class CoachReviewRequest(
    val goalVi: String,
    val levelVi: String,
    val sessionTitle: String,
    val completedToday: Boolean,
    val caloriesEaten: Int,
    val calorieLimit: Int,
    val proteinEaten: Int,
    val carbsEaten: Int,
    val fatEaten: Int,
    val sweatActive: Boolean,
    val sweatExerciseName: String,
    val sweatExtraSets: Int,
)

interface CoachReviewClient {
    suspend fun reviewToday(request: CoachReviewRequest): String?
}

class OkHttpCoachReviewClient(
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build(),
    private val endpointProvider: () -> String? = {
        BackendConfig.baseUrl?.let { "$it/api/coach-review" }
    },
) : CoachReviewClient {
    override suspend fun reviewToday(request: CoachReviewRequest): String? = withContext(Dispatchers.IO) {
        val endpoint = endpointProvider() ?: return@withContext null
        val payload = buildJsonObject {
            put("goal", request.goalVi)
            put("level", request.levelVi)
            put("sessionTitle", request.sessionTitle)
            put("completedToday", request.completedToday)
            put("caloriesEaten", request.caloriesEaten)
            put("calorieLimit", request.calorieLimit)
            put("proteinEaten", request.proteinEaten)
            put("carbsEaten", request.carbsEaten)
            put("fatEaten", request.fatEaten)
            put("sweatActive", request.sweatActive)
            put("sweatExerciseName", request.sweatExerciseName)
            put("sweatExtraSets", request.sweatExtraSets)
        }.toString()
        val httpRequest = Request.Builder()
            .url(endpoint)
            .post(payload.toRequestBody(JSON_MEDIA_TYPE))
            .build()

        client.newCall(httpRequest).execute().use { response ->
            if (!response.isSuccessful) return@withContext null
            val body = response.body?.string() ?: return@withContext null
            Json.parseToJsonElement(body).jsonObject["review"]
                ?.jsonPrimitive
                ?.content
                ?.takeIf { it.isNotBlank() }
        }
    }

    private companion object {
        val JSON_MEDIA_TYPE = "application/json; charset=utf-8".toMediaType()
    }
}
