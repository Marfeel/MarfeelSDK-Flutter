package com.marfeel.flutter

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.marfeel.compass.core.model.compass.ConversionOptions
import com.marfeel.compass.core.model.compass.ConversionScope
import com.marfeel.compass.core.model.compass.UserType
import com.marfeel.compass.core.model.multimedia.Event
import com.marfeel.compass.core.model.multimedia.MultimediaMetadata
import com.marfeel.compass.core.model.multimedia.Type
import com.marfeel.compass.tracker.CompassTracking
import com.marfeel.compass.tracker.multimedia.MultimediaTracking
import org.json.JSONObject

class MarfeelSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    companion object {
        private const val TAG = "MarfeelSdk"
        private const val CHANNEL = "com.marfeel.sdk/compass"
    }

    private lateinit var channel: MethodChannel
    private var binding: FlutterPlugin.FlutterPluginBinding? = null
    private var activityBinding: ActivityPluginBinding? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.binding = binding
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        this.binding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                val accountId = call.argument<String>("accountId")!!
                val pageTechnology = call.argument<Int>("pageTechnology")
                val context = binding?.applicationContext ?: return result.error("NO_CONTEXT", "No application context", null)
                mainHandler.post {
                    try {
                        if (pageTechnology != null) {
                            CompassTracking.initialize(context, accountId, pageTechnology)
                        } else {
                            CompassTracking.initialize(context, accountId)
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "initialize error: ${e.message}", e)
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "trackNewPage" -> {
                val url = call.argument<String>("url")!!
                val rs = call.argument<String>("rs")
                mainHandler.post {
                    try {
                        CompassTracking.getInstance().trackNewPage(url, rs)
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "trackNewPage error: ${e.message}", e)
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "trackScreen" -> {
                val screen = call.argument<String>("screen")!!
                val rs = call.argument<String>("rs")
                mainHandler.post {
                    try {
                        CompassTracking.getInstance().trackScreen(screen, rs)
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "trackScreen error: ${e.message}", e)
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "stopTracking" -> {
                mainHandler.post {
                    try {
                        CompassTracking.getInstance().stopTracking()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "setLandingPage" -> {
                val landingPage = call.argument<String>("landingPage")!!
                mainHandler.post {
                    try {
                        CompassTracking.getInstance().setLandingPage(landingPage)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "setSiteUserId" -> {
                val userId = call.argument<String>("userId")!!
                mainHandler.post {
                    try {
                        CompassTracking.getInstance().setSiteUserId(userId)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "getUserId" -> {
                mainHandler.post {
                    try {
                        val userId = CompassTracking.getInstance().getUserId()
                        result.success(userId)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "setUserType" -> {
                val userType = call.argument<Int>("userType")!!
                mainHandler.post {
                    try {
                        val type = when (userType) {
                            1 -> UserType.Anonymous
                            2 -> UserType.Logged
                            3 -> UserType.Paid
                            else -> UserType.Custom(userType)
                        }
                        CompassTracking.getInstance().setUserType(type)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "getRFV" -> {
                mainHandler.post {
                    try {
                        CompassTracking.getInstance().getRFV { rfv ->
                            result.success(rfv)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "setPageVar" -> {
                val name = call.argument<String>("name")!!
                val value = call.argument<String>("value")!!
                mainHandler.post {
                    try {
                        CompassTracking.getInstance().setPageVar(name, value)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "setPageMetric" -> {
                val name = call.argument<String>("name")!!
                val value = call.argument<Int>("value")!!
                mainHandler.post {
                    try {
                        CompassTracking.getInstance().setPageMetric(name, value)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "setSessionVar" -> {
                val name = call.argument<String>("name")!!
                val value = call.argument<String>("value")!!
                mainHandler.post {
                    try {
                        CompassTracking.getInstance().setSessionVar(name, value)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "setUserVar" -> {
                val name = call.argument<String>("name")!!
                val value = call.argument<String>("value")!!
                mainHandler.post {
                    try {
                        CompassTracking.getInstance().setUserVar(name, value)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "addUserSegment" -> {
                val segment = call.argument<String>("segment")!!
                mainHandler.post {
                    try {
                        CompassTracking.getInstance().addUserSegment(segment)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "setUserSegments" -> {
                val segments = call.argument<List<String>>("segments")!!
                mainHandler.post {
                    try {
                        CompassTracking.getInstance().setUserSegments(segments)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "removeUserSegment" -> {
                val segment = call.argument<String>("segment")!!
                mainHandler.post {
                    try {
                        CompassTracking.getInstance().removeUserSegment(segment)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "clearUserSegments" -> {
                mainHandler.post {
                    try {
                        CompassTracking.getInstance().clearUserSegments()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "trackConversion" -> {
                val conversion = call.argument<String>("conversion")!!
                val initiator = call.argument<String>("initiator")
                val id = call.argument<String>("id")
                val value = call.argument<String>("value")
                val meta = call.argument<Map<String, String>>("meta")
                val scope = call.argument<String>("scope")
                mainHandler.post {
                    try {
                        val conversionScope = when (scope) {
                            "user" -> ConversionScope.User
                            "session" -> ConversionScope.Session
                            "page" -> ConversionScope.Page
                            else -> null
                        }
                        if (initiator == null && id == null && value == null && meta == null && conversionScope == null) {
                            CompassTracking.getInstance().trackConversion(conversion)
                        } else {
                            CompassTracking.getInstance().trackConversion(
                                conversion,
                                ConversionOptions(
                                    initiator = initiator,
                                    id = id,
                                    value = value,
                                    meta = meta,
                                    scope = conversionScope
                                )
                            )
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "setConsent" -> {
                val hasConsent = call.argument<Boolean>("hasConsent")!!
                mainHandler.post {
                    try {
                        CompassTracking.getInstance().setUserConsent(hasConsent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "updateScrollPercentage" -> {
                val percentage = call.argument<Int>("percentage")!!
                mainHandler.post {
                    try {
                        CompassTracking.getInstance().updateScrollPercentage(percentage)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "initializeMultimediaItem" -> {
                val id = call.argument<String>("id")!!
                val provider = call.argument<String>("provider")!!
                val providerId = call.argument<String>("providerId")!!
                val type = call.argument<String>("type")!!
                val metadataJson = call.argument<String>("metadata")!!
                mainHandler.post {
                    try {
                        val mediaType = if (type == "audio") Type.AUDIO else Type.VIDEO
                        val json = JSONObject(metadataJson)
                        val metadata = MultimediaMetadata(
                            isLive = if (json.has("isLive")) json.getBoolean("isLive") else false,
                            title = if (json.has("title")) json.getString("title") else null,
                            description = if (json.has("description")) json.getString("description") else null,
                            url = if (json.has("url")) json.getString("url") else null,
                            thumbnail = if (json.has("thumbnail")) json.getString("thumbnail") else null,
                            authors = if (json.has("authors")) json.getString("authors") else null,
                            publishTime = if (json.has("publishTime")) json.getLong("publishTime") else null,
                            duration = if (json.has("duration")) json.getInt("duration") else null
                        )
                        MultimediaTracking.getInstance().initializeItem(id, provider, providerId, mediaType, metadata)
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "initializeMultimediaItem error: ${e.message}", e)
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            "registerMultimediaEvent" -> {
                val id = call.argument<String>("id")!!
                val event = call.argument<String>("event")!!
                val eventTime = call.argument<Int>("eventTime")!!
                val mediaEvent = when (event) {
                    "play" -> Event.PLAY
                    "pause" -> Event.PAUSE
                    "end" -> Event.END
                    "updateCurrentTime" -> Event.UPDATE_CURRENT_TIME
                    "adPlay" -> Event.AD_PLAY
                    "mute" -> Event.MUTE
                    "unmute" -> Event.UNMUTE
                    "fullscreen" -> Event.FULL_SCREEN
                    "backscreen" -> Event.BACK_SCREEN
                    "enterViewport" -> Event.ENTER_VIEWPORT
                    "leaveViewport" -> Event.LEAVE_VIEWPORT
                    else -> return result.error("INVALID_EVENT", "Unknown event: $event", null)
                }
                mainHandler.post {
                    try {
                        MultimediaTracking.getInstance().registerEvent(id, mediaEvent, eventTime)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
            }

            else -> result.notImplemented()
        }
    }

}
