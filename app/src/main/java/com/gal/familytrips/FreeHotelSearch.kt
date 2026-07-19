package com.gal.familytrips

import android.net.Uri
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale

data class FreeHotelSuggestion(
    val id: String,
    val name: String,
    val address: String,
    val latitude: Double?,
    val longitude: Double?,
    val source: String = ""
)

object FreeHotelSearch {
    suspend fun search(
        query: String,
        destination: String,
        limit: Int = 10
    ): List<FreeHotelSuggestion> = withContext(Dispatchers.IO) {
        val normalizedQuery = query.trim()
        if (normalizedQuery.length < 2) {
            return@withContext emptyList()
        }

        val photonResults = searchPhoton(normalizedQuery, destination, limit)
        val nominatimResults = if (photonResults.size < 4) {
            searchNominatim(normalizedQuery, destination, limit)
        } else {
            emptyList()
        }

        rankAndMerge(
            query = normalizedQuery,
            destination = destination,
            results = photonResults + nominatimResults,
            limit = limit
        )
    }

    private fun searchPhoton(
        query: String,
        destination: String,
        limit: Int
    ): List<FreeHotelSuggestion> {
        val variants = listOf(
            "$query $destination",
            "$query hotel $destination",
            query
        ).distinct()

        val results = mutableListOf<FreeHotelSuggestion>()

        variants.forEachIndexed { variantIndex, fullQuery ->
            val url = URL(
                "https://photon.komoot.io/api/?" +
                    "q=${Uri.encode(fullQuery)}" +
                    "&limit=${limit.coerceAtMost(15)}" +
                    "&lang=en"
            )

            request(url)?.let { payload ->
                results += parsePhoton(payload, "photon-$variantIndex")
            }
        }

        return results
    }

    private fun searchNominatim(
        query: String,
        destination: String,
        limit: Int
    ): List<FreeHotelSuggestion> {
        val variants = listOf(
            "$query, $destination",
            "$query hotel, $destination",
            query
        ).distinct()

        val results = mutableListOf<FreeHotelSuggestion>()

        variants.forEachIndexed { variantIndex, fullQuery ->
            val url = URL(
                "https://nominatim.openstreetmap.org/search" +
                    "?q=${Uri.encode(fullQuery)}" +
                    "&format=jsonv2" +
                    "&addressdetails=1" +
                    "&limit=${limit.coerceAtMost(10)}"
            )

            request(url)?.let { payload ->
                results += parseNominatim(payload, "nominatim-$variantIndex")
            }
        }

        return results
    }

    private fun request(url: URL): String? {
        val connection = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 12_000
            readTimeout = 12_000
            setRequestProperty(
                "User-Agent",
                "GalFamilyTrips/3.6.2 Android"
            )
            setRequestProperty("Accept", "application/json")
            setRequestProperty("Accept-Language", "en")
        }

        return try {
            if (connection.responseCode !in 200..299) {
                null
            } else {
                connection.inputStream
                    .bufferedReader()
                    .use { it.readText() }
            }
        } catch (_: Exception) {
            null
        } finally {
            connection.disconnect()
        }
    }

    private fun parsePhoton(
        payload: String,
        prefix: String
    ): List<FreeHotelSuggestion> {
        val root = runCatching { JSONObject(payload) }.getOrNull()
            ?: return emptyList()
        val features = root.optJSONArray("features")
            ?: return emptyList()

        return buildList {
            for (index in 0 until features.length()) {
                val feature = features.optJSONObject(index) ?: continue
                val properties = feature.optJSONObject("properties")
                    ?: continue
                val coordinates = feature
                    .optJSONObject("geometry")
                    ?.optJSONArray("coordinates")

                val name = firstNonBlank(
                    properties.optString("name"),
                    properties.optString("street"),
                    properties.optString("city"),
                    properties.optString("district")
                ) ?: continue

                val address = buildAddress(
                    properties.optString("housenumber"),
                    properties.optString("street"),
                    properties.optString("district"),
                    properties.optString("city"),
                    properties.optString("state"),
                    properties.optString("postcode"),
                    properties.optString("country")
                ).ifBlank { name }

                add(
                    FreeHotelSuggestion(
                        id = "$prefix-${properties.optString("osm_type")}-" +
                            "${properties.optString("osm_id")}-$index",
                        name = name,
                        address = address,
                        latitude = coordinates
                            ?.optDouble(1)
                            ?.takeUnless(Double::isNaN),
                        longitude = coordinates
                            ?.optDouble(0)
                            ?.takeUnless(Double::isNaN),
                        source = "Photon"
                    )
                )
            }
        }
    }

    private fun parseNominatim(
        payload: String,
        prefix: String
    ): List<FreeHotelSuggestion> {
        val array = runCatching { JSONArray(payload) }.getOrNull()
            ?: return emptyList()

        return buildList {
            for (index in 0 until array.length()) {
                val item = array.optJSONObject(index) ?: continue
                val addressObject = item.optJSONObject("address")
                val displayName = item.optString("display_name")

                val name = firstNonBlank(
                    item.optString("name"),
                    addressObject?.optString("hotel").orEmpty(),
                    displayName.substringBefore(",")
                ) ?: continue

                add(
                    FreeHotelSuggestion(
                        id = "$prefix-${item.optString("osm_type")}-" +
                            "${item.optString("osm_id")}-$index",
                        name = name,
                        address = displayName.ifBlank { name },
                        latitude = item.optString("lat").toDoubleOrNull(),
                        longitude = item.optString("lon").toDoubleOrNull(),
                        source = "Nominatim"
                    )
                )
            }
        }
    }

    private fun rankAndMerge(
        query: String,
        destination: String,
        results: List<FreeHotelSuggestion>,
        limit: Int
    ): List<FreeHotelSuggestion> {
        val queryTokens = tokenize(query)
        val destinationTokens = tokenize(destination)

        return results
            .distinctBy {
                "${normalize(it.name)}|${normalize(it.address)}|" +
                    "${it.latitude}|${it.longitude}"
            }
            .map { suggestion ->
                val combined = normalize(
                    "${suggestion.name} ${suggestion.address}"
                )
                var score = 0

                queryTokens.forEach { token ->
                    if (normalize(suggestion.name).contains(token)) score += 18
                    if (combined.contains(token)) score += 8
                }

                destinationTokens.forEach { token ->
                    if (combined.contains(token)) score += 4
                }

                if (
                    listOf(
                        "hotel",
                        "hostel",
                        "motel",
                        "resort",
                        "inn",
                        "apart",
                        "suite",
                        "lodge",
                        "guest",
                        "מלון"
                    ).any { combined.contains(it) }
                ) {
                    score += 8
                }

                suggestion to score
            }
            .sortedByDescending { it.second }
            .map { it.first }
            .take(limit)
    }

    private fun tokenize(value: String): List<String> =
        normalize(value)
            .split(" ")
            .filter { it.length >= 2 }
            .distinct()

    private fun normalize(value: String): String =
        value
            .lowercase(Locale.ROOT)
            .replace(Regex("[^\\p{L}\\p{N}]+"), " ")
            .replace(Regex("\\s+"), " ")
            .trim()

    private fun firstNonBlank(vararg values: String): String? =
        values.firstOrNull { it.isNotBlank() }

    private fun buildAddress(vararg parts: String): String =
        parts
            .filter { it.isNotBlank() }
            .distinct()
            .joinToString(", ")
}
