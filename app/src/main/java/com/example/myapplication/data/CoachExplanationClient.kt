package com.example.myapplication.data

import com.example.myapplication.core.adaptation.AdaptationKind
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

interface CoachExplanationClient {
    suspend fun explainDecision(
        kind: AdaptationKind,
        reasonVi: String,
        beforeValue: String,
        afterValue: String,
    ): String?
}

class OkHttpCoachExplanationClient(
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .build(),
    private val endpointUrl: String = "http://10.0.2.2:3000/api/explain-decision",
) : CoachExplanationClient {
    override suspend fun explainDecision(
        kind: AdaptationKind,
        reasonVi: String,
        beforeValue: String,
        afterValue: String,
    ): String? = withContext(Dispatchers.IO) {
        val payload = buildJsonObject {
            put("kind", kind.name)
            put("reasonVi", reasonVi)
            put("beforeValue", beforeValue)
            put("afterValue", afterValue)
        }.toString()

        val request = Request.Builder()
            .url(endpointUrl)
            .post(payload.toRequestBody("application/json".toMediaType()))
            .build()

        try {
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) return@withContext null
                val bodyString = response.body?.string() ?: return@withContext null
                val element = Json.parseToJsonElement(bodyString).jsonObject
                val explanation = element["explanation"]?.jsonPrimitive?.content
                if (explanation.isNullOrBlank()) null else explanation
            }
        } catch (e: Exception) {
            null // Fallback locally on timeout or network error
        }
    }
}
