package com.example.smriti_jyoti

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.annotation.NonNull
import androidx.core.app.NotificationCompat
import android.media.AudioAttributes
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.aninai/notifications"
    private val STEP_CHANNEL = "com.aninai/step_tracker"
    private val NOTIFICATION_CHANNEL_ID = "aninai_reminders_v4"
    private val NOTIFICATION_CHANNEL_NAME = "Aninai Reminders"
    private var pendingActivityPermissionResult: MethodChannel.Result? = null

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 102) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED
            pendingActivityPermissionResult?.success(granted)
            pendingActivityPermissionResult = null
        }
    }

    companion object {
        private var channel: MethodChannel? = null
        var activityInstance: MainActivity? = null
        var isAppInForeground: Boolean = false
        private var pendingReminderId: String? = null
        private var pendingActionType: String? = null

        fun sendNotificationActionToFlutter(reminderId: String, actionType: String) {
            if (channel != null && activityInstance != null) {
                activityInstance?.runOnUiThread {
                    channel?.invokeMethod("onNotificationAction", mapOf(
                        "reminderId" to reminderId,
                        "actionType" to actionType
                    ))
                }
            } else {
                pendingReminderId = reminderId
                pendingActionType = actionType
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntentAction(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntentAction(intent)
    }

    override fun onResume() {
        super.onResume()
        activityInstance = this
        isAppInForeground = true
    }

    override fun onPause() {
        super.onPause()
        isAppInForeground = false
    }

    override fun onDestroy() {
        if (activityInstance === this) {
            activityInstance = null
        }
        isAppInForeground = false
        super.onDestroy()
    }

    private fun handleIntentAction(intent: Intent?) {
        val reminderId = intent?.getStringExtra("reminderId")
        val actionType = intent?.getStringExtra("actionType")
        if (!reminderId.isNullOrEmpty() && !actionType.isNullOrEmpty()) {
            sendNotificationActionToFlutter(reminderId, actionType)
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        activityInstance = this
        createNotificationChannel()

        val mChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel = mChannel

        if (pendingReminderId != null && pendingActionType != null) {
            sendNotificationActionToFlutter(pendingReminderId!!, pendingActionType!!)
            pendingReminderId = null
            pendingActionType = null
        }

        mChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> {
                    val title = call.argument<String>("title") ?: "Aninai Reminder"
                    val body = call.argument<String>("body") ?: "You have a scheduled reminder."
                    val id = call.argument<Int>("id") ?: (System.currentTimeMillis() % 100000).toInt()
                    val reminderId = call.argument<String>("reminderId") ?: ""
                    val takenLabel = call.argument<String>("takenLabel") ?: "Taken"
                    val yetToTakeLabel = call.argument<String>("yetToTakeLabel") ?: "Yet to Take"
                    val isHydration = call.argument<Boolean>("isHydration") ?: false
                    val showActions = call.argument<Boolean>("showActions") ?: true
                    val medicineImagePath = call.argument<String>("medicineImagePath") ?: ""
                    val pillsCount = call.argument<String>("pillsCount") ?: ""

                    showSystemNotification(id, reminderId, title, body, takenLabel, yetToTakeLabel, isHydration, showActions, medicineImagePath, pillsCount)
                    result.success(true)
                }
                "requestPermission" -> {
                    if (Build.VERSION.SDK_INT >= 33) {
                        requestPermissions(arrayOf("android.permission.POST_NOTIFICATIONS"), 101)
                    }
                    result.success(true)
                }
                "scheduleAlarm" -> {
                    val id = call.argument<Int>("id") ?: 0
                    val triggerAtMs = (call.argument<Number>("triggerAtMs"))?.toLong() ?: 0L
                    val title = call.argument<String>("title") ?: ""
                    val body = call.argument<String>("body") ?: ""
                    val reminderId = call.argument<String>("reminderId") ?: ""
                    val takenLabel = call.argument<String>("takenLabel") ?: "Taken"
                    val yetToTakeLabel = call.argument<String>("yetToTakeLabel") ?: "Yet to Take"
                    val spokenText = call.argument<String>("spokenText") ?: "$title. $body"
                    val fallbackText = call.argument<String>("fallbackText") ?: spokenText
                    val customVoicePath = call.argument<String>("customVoicePath") ?: ""
                    val voiceMode = call.argument<Int>("voiceMode") ?: 0
                    val clonedVoiceSamplePath = call.argument<String>("clonedVoiceSamplePath") ?: ""
                    val langCode = call.argument<String>("langCode") ?: "en"
                    val isHydration = call.argument<Boolean>("isHydration") ?: false
                    val showActions = call.argument<Boolean>("showActions") ?: true
                    val medicineImagePath = call.argument<String>("medicineImagePath") ?: ""
                    val pillsCount = call.argument<String>("pillsCount") ?: ""

                    if (id != 0 && triggerAtMs > System.currentTimeMillis()) {
                        scheduleNativeAlarm(id, triggerAtMs, title, body, reminderId, takenLabel, yetToTakeLabel, spokenText, fallbackText, customVoicePath, voiceMode, clonedVoiceSamplePath, langCode, isHydration, showActions, medicineImagePath, pillsCount)
                    }
                    result.success(true)
                }
                "cancelAlarm" -> {
                    val id = call.argument<Int>("id") ?: 0
                    if (id != 0) {
                        cancelNativeAlarm(id)
                    }
                    result.success(true)
                }
                "playEmergencyBeepAlarm" -> {
                    playEmergencyBeepAlarmSound(applicationContext)
                    result.success(true)
                }
                "startLocationSharingNotification" -> {
                    val title = call.argument<String>("title") ?: "Location sharing is active"
                    val body = call.argument<String>("body") ?: "Your location is being shared with your caregiver."
                    showLocationSharingNotification(title, body)
                    result.success(true)
                }
                "stopLocationSharingNotification" -> {
                    cancelLocationSharingNotification()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        val stepChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STEP_CHANNEL)
        val stepManager = StepCounterManager.getInstance(applicationContext)
        stepManager.addStepUpdateListener {
            runOnUiThread {
                try {
                    stepChannel.invokeMethod("onStepCountChanged", stepManager.getTodayStepsData())
                } catch (_: Exception) {}
            }
        }

        stepChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isSensorAvailable" -> {
                    result.success(stepManager.isSensorAvailable())
                }
                "hasPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val granted = checkSelfPermission(android.Manifest.permission.ACTIVITY_RECOGNITION) == android.content.pm.PackageManager.PERMISSION_GRANTED
                        result.success(granted)
                    } else {
                        result.success(true)
                    }
                }
                "requestPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val granted = checkSelfPermission(android.Manifest.permission.ACTIVITY_RECOGNITION) == android.content.pm.PackageManager.PERMISSION_GRANTED
                        if (granted) {
                            result.success(true)
                        } else {
                            pendingActivityPermissionResult = result
                            requestPermissions(arrayOf(android.Manifest.permission.ACTIVITY_RECOGNITION), 102)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "startTracking" -> {
                    StepTrackingService.startService(applicationContext)
                    result.success(true)
                }
                "stopTracking" -> {
                    StepTrackingService.stopService(applicationContext)
                    result.success(true)
                }
                "isTrackingActive" -> {
                    result.success(StepTrackingService.isServiceRunning || stepManager.isTrackingEnabled())
                }
                "getTodaySteps" -> {
                    result.success(stepManager.getTodayStepsData())
                }
                "getStepHistory" -> {
                    result.success(stepManager.getDailyStepHistory())
                }
                "setDailyGoal" -> {
                    val goal = call.argument<Int>("goal") ?: 10000
                    stepManager.setDailyGoal(goal)
                    result.success(true)
                }
                "refreshToday" -> {
                    stepManager.checkDateRollover()
                    result.success(stepManager.getTodayStepsData())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun scheduleNativeAlarm(
        id: Int,
        triggerAtMs: Long,
        title: String,
        body: String,
        reminderId: String,
        takenLabel: String,
        yetToTakeLabel: String,
        spokenText: String,
        fallbackText: String,
        customVoicePath: String,
        voiceMode: Int,
        clonedVoiceSamplePath: String,
        langCode: String,
        isHydration: Boolean,
        showActions: Boolean = true,
        medicineImagePath: String = "",
        pillsCount: String = ""
    ) {
        try {
            val isRoutine = reminderId.startsWith("act_") || reminderId.contains("act") || reminderId.contains("routine") ||
                    title.contains("Daily Activity") || title.contains("தினசரி") || title.contains("dinasari")
            val effectiveCustomVoicePath = customVoicePath
            var effectiveVoiceMode = voiceMode
            if (effectiveCustomVoicePath.isNotEmpty() && java.io.File(effectiveCustomVoicePath).exists() && java.io.File(effectiveCustomVoicePath).length() > 0) {
                effectiveVoiceMode = 1
            }
            val effectiveClonedVoiceSamplePath = clonedVoiceSamplePath

            val finalTakenLabel = if (takenLabel.isEmpty() || takenLabel == "startedBtn" || takenLabel == "takenBtn") {
                if (isRoutine) (if (langCode == "ta") "தொடங்கப்பட்டது" else "Started")
                else (if (langCode == "ta") "எடுத்துக்கொண்டேன்" else "Taken")
            } else {
                takenLabel
            }

            val finalYetToTakeLabel = if (yetToTakeLabel.isEmpty() || yetToTakeLabel == "notStartedBtn" || yetToTakeLabel == "yetToTakeBtn") {
                if (isRoutine) (if (langCode == "ta") "தொடங்கவில்லை" else "Not Started")
                else (if (langCode == "ta") "எடுக்கவில்லை" else "Yet to Take")
            } else {
                yetToTakeLabel
            }

            val prefs = getSharedPreferences("aninai_native_alarms", Context.MODE_PRIVATE)
            val valueStr = "$id|||$triggerAtMs|||$title|||$body|||$reminderId|||$finalTakenLabel|||$finalYetToTakeLabel|||$spokenText|||$langCode|||$isHydration|||$effectiveCustomVoicePath|||$effectiveVoiceMode|||$effectiveClonedVoiceSamplePath|||$fallbackText|||$showActions|||$medicineImagePath|||$pillsCount"
            prefs.edit().putString(id.toString(), valueStr).apply()

            val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
            val intent = Intent(this, AlarmReceiver::class.java).apply {
                action = "com.aninai.ACTION_TRIGGER_ALARM"
                putExtra("id", id)
                putExtra("title", title)
                putExtra("body", body)
                putExtra("reminderId", reminderId)
                putExtra("takenLabel", finalTakenLabel)
                putExtra("yetToTakeLabel", finalYetToTakeLabel)
                putExtra("spokenText", spokenText)
                putExtra("fallbackText", fallbackText)
                putExtra("customVoicePath", effectiveCustomVoicePath)
                putExtra("voiceMode", effectiveVoiceMode)
                putExtra("clonedVoiceSamplePath", effectiveClonedVoiceSamplePath)
                putExtra("langCode", langCode)
                putExtra("isHydration", isHydration)
                putExtra("showActions", showActions)
                putExtra("medicineImagePath", medicineImagePath)
                putExtra("pillsCount", pillsCount)
            }

            val pendingIntent = PendingIntent.getBroadcast(
                this,
                id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    val alarmClockInfo = android.app.AlarmManager.AlarmClockInfo(triggerAtMs, pendingIntent)
                    alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        android.app.AlarmManager.RTC_WAKEUP,
                        triggerAtMs,
                        pendingIntent
                    )
                } else {
                    alarmManager.setExact(
                        android.app.AlarmManager.RTC_WAKEUP,
                        triggerAtMs,
                        pendingIntent
                    )
                }
            } catch (e: Exception) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        android.app.AlarmManager.RTC_WAKEUP,
                        triggerAtMs,
                        pendingIntent
                    )
                } else {
                    alarmManager.setExact(
                        android.app.AlarmManager.RTC_WAKEUP,
                        triggerAtMs,
                        pendingIntent
                    )
                }
            }
        } catch (_: Exception) {}
    }

    private fun cancelNativeAlarm(id: Int) {
        try {
            val prefs = getSharedPreferences("aninai_native_alarms", Context.MODE_PRIVATE)
            prefs.edit().remove(id.toString()).apply()

            val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
            val intent = Intent(this, AlarmReceiver::class.java).apply {
                action = "com.aninai.ACTION_TRIGGER_ALARM"
            }
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
        } catch (_: Exception) {}
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            try {
                notificationManager.deleteNotificationChannel("aninai_reminders")
                notificationManager.deleteNotificationChannel("aninai_reminders_v2")
                notificationManager.deleteNotificationChannel("aninai_reminders_v3")
            } catch (_: Exception) {}

            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "High Priority Elder Reminders, Medicine, Hydration & Appointments"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 250, 500)
                enableLights(true)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showSystemNotification(
        id: Int,
        reminderId: String,
        title: String,
        body: String,
        takenLabel: String,
        yetToTakeLabel: String,
        isHydration: Boolean,
        showActions: Boolean = true,
        medicineImagePath: String = "",
        pillsCount: String = ""
    ) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Main app launch intent on notification tap
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }

        val activityFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(this, id, intent, activityFlags)

        val broadcastFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        // Action 1: TAKEN (Localized)
        val takenIntent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = "com.aninai.ACTION_TAKEN"
            putExtra("reminderId", reminderId)
            putExtra("notificationId", id)
        }
        val takenPendingIntent = PendingIntent.getBroadcast(this, id * 10 + 1, takenIntent, broadcastFlags)

        // Action 2: YET TO TAKE (Localized)
        val yetToTakeIntent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = "com.aninai.ACTION_YET_TO_TAKE"
            putExtra("reminderId", reminderId)
            putExtra("notificationId", id)
        }
        val yetToTakePendingIntent = PendingIntent.getBroadcast(this, id * 10 + 2, yetToTakeIntent, broadcastFlags)

        var iconRes = applicationInfo.icon
        if (iconRes == 0) {
            iconRes = R.mipmap.ic_launcher
        }

        val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(iconRes)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setVibrate(longArrayOf(0, 500, 250, 500))
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)

        val isAppointment = isAppointmentReminder(reminderId, title, body)
        if (isHydration) {
            val logWaterIntent = Intent(this, NotificationActionReceiver::class.java).apply {
                action = "com.aninai.ACTION_LOG_WATER"
                putExtra("reminderId", if (reminderId.isNotEmpty()) reminderId else "hyd")
                putExtra("notificationId", id)
                putExtra("isHydration", true)
            }
            val logWaterPendingIntent = PendingIntent.getBroadcast(this, id * 10 + 3, logWaterIntent, broadcastFlags)
            val logBtnText = if (takenLabel.isNotEmpty() && takenLabel != "Taken") takenLabel else "💧 Log 1 Glass Water"
            val actionLogWater = NotificationCompat.Action.Builder(
                0,
                logBtnText,
                logWaterPendingIntent
            ).build()
            builder.addAction(actionLogWater)
        } else if (showActions && !isAppointment) {
            val actionTaken = NotificationCompat.Action.Builder(
                0,
                "✅ $takenLabel",
                takenPendingIntent
            ).build()

            val actionYetToTake = NotificationCompat.Action.Builder(
                0,
                "⏳ $yetToTakeLabel",
                yetToTakePendingIntent
            ).build()

            builder.addAction(actionTaken)
            builder.addAction(actionYetToTake)
        }

        notificationManager.notify(id, builder.build())
    }

    private fun isAppointmentReminder(reminderId: String, title: String, body: String): Boolean {
        val idLower = reminderId.lowercase()
        val titleLower = title.lowercase()
        val bodyLower = body.lowercase()
        return idLower.startsWith("apt_") || idLower.contains("apt") || idLower.contains("appointment") ||
                titleLower.contains("doctor") || titleLower.contains("appointment") || titleLower.contains("மருத்துவர்") || titleLower.contains("சந்திப்பு") || titleLower.contains("maruthuva") || titleLower.contains("sandhippu") ||
                bodyLower.contains("doctor") || bodyLower.contains("appointment") || bodyLower.contains("மருத்துவர்") || bodyLower.contains("சந்திப்பு") || bodyLower.contains("maruthuva") || bodyLower.contains("sandhippu")
    }

    private fun playEmergencyBeepAlarmSound(context: Context) {
        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager
            val maxAlarm = audioManager.getStreamMaxVolume(android.media.AudioManager.STREAM_ALARM)
            audioManager.setStreamVolume(android.media.AudioManager.STREAM_ALARM, maxAlarm, 0)

            var alarmUri = android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_ALARM)
            if (alarmUri == null) {
                alarmUri = android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION)
            }
            if (alarmUri == null) {
                alarmUri = android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_RINGTONE)
            }

            val ringtone = android.media.RingtoneManager.getRingtone(context, alarmUri)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                ringtone?.audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            }
            ringtone?.play()

            Thread {
                try {
                    val toneGen = android.media.ToneGenerator(android.media.AudioManager.STREAM_ALARM, 100)
                    for (i in 1..8) {
                        toneGen.startTone(android.media.ToneGenerator.TONE_CDMA_EMERGENCY_RINGBACK, 500)
                        Thread.sleep(600)
                        toneGen.startTone(android.media.ToneGenerator.TONE_SUP_ERROR, 500)
                        Thread.sleep(600)
                    }
                    toneGen.release()
                } catch (e: Exception) {
                    android.util.Log.e("AninaiTTS", "Error generating emergency beep tones", e)
                }
            }.start()

            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                try { ringtone?.stop() } catch (_: Exception) {}
            }, 10000)

            android.util.Log.d("AninaiTTS", "Played Emergency Beep Alarm Sound for Caregiver Alert")
        } catch (e: Exception) {
            android.util.Log.e("AninaiTTS", "Error playing emergency beep alarm sound", e)
        }
    }

    private val LOCATION_NOTIFICATION_ID = 99999
    private val LOCATION_CHANNEL_ID = "aninai_location_tracking"
    private val LOCATION_CHANNEL_NAME = "Elder Location Tracking"

    private fun showLocationSharingNotification(title: String, body: String) {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val locChannel = NotificationChannel(
                    LOCATION_CHANNEL_ID,
                    LOCATION_CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Shows persistent status when Elder location sharing is active"
                    setShowBadge(false)
                }
                notificationManager.createNotificationChannel(locChannel)
            }

            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getActivity(this, LOCATION_NOTIFICATION_ID, intent, flags)

            var iconRes = applicationInfo.icon
            if (iconRes == 0) {
                iconRes = R.mipmap.ic_launcher
            }

            val builder = NotificationCompat.Builder(this, LOCATION_CHANNEL_ID)
                .setSmallIcon(iconRes)
                .setContentTitle(title)
                .setContentText(body)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)

            notificationManager.notify(LOCATION_NOTIFICATION_ID, builder.build())
        } catch (e: Exception) {
            android.util.Log.e("AninaiLocation", "Error showing location notification", e)
        }
    }

    private fun cancelLocationSharingNotification() {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(LOCATION_NOTIFICATION_ID)
        } catch (_: Exception) {}
    }
}

