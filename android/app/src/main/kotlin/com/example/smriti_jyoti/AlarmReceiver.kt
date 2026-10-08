package com.example.smriti_jyoti

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.os.Build
import android.os.PowerManager
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import androidx.core.app.NotificationCompat
import java.util.Locale

class AlarmReceiver : BroadcastReceiver() {
    private val NOTIFICATION_CHANNEL_ID = "aninai_reminders_v4"
    private val NOTIFICATION_CHANNEL_NAME = "Aninai Reminders"

    companion object {
        @JvmStatic
        private var activeTtsEngine: TextToSpeech? = null
        @JvmStatic
        private var activeWakeLock: PowerManager.WakeLock? = null
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        val action = intent.action ?: ""

        if (action == Intent.ACTION_BOOT_COMPLETED || action == "android.intent.action.QUICKBOOT_POWERON") {
            restoreAlarmsOnBoot(context)
            try {
                val stepManager = StepCounterManager.getInstance(context)
                if (stepManager.isTrackingEnabled()) {
                    StepTrackingService.startService(context)
                    android.util.Log.d("AninaiSteps", "Restored StepTrackingService on boot")
                }
            } catch (e: Exception) {
                android.util.Log.e("AninaiSteps", "Error restoring StepTrackingService on boot", e)
            }
            return
        }

        if (action == "com.aninai.ACTION_TRIGGER_ALARM") {
            val attemptCount = intent.getIntExtra("attemptCount", 1)
            try {
                val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val userJson = flutterPrefs.getString("flutter.aninai_user", "") ?: ""
                val isCaretaker = userJson.contains("\"role\":\"caretaker\"") || userJson.contains("\"role\": \"caretaker\"")

                if (attemptCount < 4 && isCaretaker) {
                    android.util.Log.d("AninaiTTS", "Attempts 1-3 are Elder only. Suppressing for Caregiver.")
                    return
                }
                if (attemptCount >= 4 && !isCaretaker) {
                    android.util.Log.d("AninaiTTS", "Attempt 4 Caregiver SOS alert is Caregiver only. Suppressing for Elder.")
                    return
                }
            } catch (e: Exception) {
                android.util.Log.e("AninaiTTS", "Error checking caregiver role in AlarmReceiver", e)
            }
            val title = intent.getStringExtra("title") ?: "Aninai Reminder"
            val body = intent.getStringExtra("body") ?: "You have a scheduled reminder."
            val id = intent.getIntExtra("id", (System.currentTimeMillis() % 100000).toInt())
            val reminderId = intent.getStringExtra("reminderId") ?: ""
            val rawTakenLabel = intent.getStringExtra("takenLabel") ?: ""
            val rawYetToTakeLabel = intent.getStringExtra("yetToTakeLabel") ?: ""
            val isHydration = intent.getBooleanExtra("isHydration", false)
            val medicineImagePath = intent.getStringExtra("medicineImagePath") ?: ""
            val pillsCount = intent.getStringExtra("pillsCount") ?: ""
            val spokenText = intent.getStringExtra("spokenText") ?: "$title. $body"
            val fallbackText = intent.getStringExtra("fallbackText") ?: ""
            val customVoicePath = intent.getStringExtra("customVoicePath") ?: ""
            val voiceMode = intent.getIntExtra("voiceMode", 0)
            val clonedVoiceSamplePath = intent.getStringExtra("clonedVoiceSamplePath") ?: ""
            val langCode = intent.getStringExtra("langCode") ?: "en"

            val isAppt = reminderId.startsWith("apt_") || reminderId.contains("apt") || reminderId.contains("appointment") || isAppointmentReminder(reminderId, title, body, spokenText)
            val isRoutine = reminderId.startsWith("act_") || reminderId.contains("act") || reminderId.contains("routine") ||
                    title.contains("Daily Activity") || title.contains("தினசரி") || title.contains("dinasari") ||
                    body.contains("Daily Activity") || body.contains("தினசரி")
            val showActions = if (isAppt || attemptCount >= 4) false else intent.getBooleanExtra("showActions", reminderId.startsWith("med_") || reminderId.startsWith("act_") || isRoutine)

            val takenLabel = if (rawTakenLabel.isEmpty() || rawTakenLabel == "startedBtn" || rawTakenLabel == "takenBtn" || rawTakenLabel == "attendedBtn") {
                if (isAppt) (if (langCode == "ta") "சென்றேன்" else "Attended")
                else if (isRoutine) (if (langCode == "ta") "தொடங்கப்பட்டது" else "Started")
                else (if (langCode == "ta") "எடுத்துக்கொண்டேன்" else "Taken")
            } else {
                rawTakenLabel
            }

            val yetToTakeLabel = if (rawYetToTakeLabel.isEmpty() || rawYetToTakeLabel == "notStartedBtn" || rawYetToTakeLabel == "yetToTakeBtn" || rawYetToTakeLabel == "notAttendedBtn") {
                if (isAppt) (if (langCode == "ta") "செல்லவில்லை" else "Not Attended")
                else if (isRoutine) (if (langCode == "ta") "தொடங்கவில்லை" else "Not Started")
                else (if (langCode == "ta") "எடுக்கவில்லை" else "Yet to Take")
            } else {
                rawYetToTakeLabel
            }

            var effectiveCustomVoicePath = if (isAppt) "" else customVoicePath
            var effectiveVoiceMode = if (isAppt) 0 else voiceMode

            if (!isAppt && effectiveCustomVoicePath.isNotEmpty() && java.io.File(effectiveCustomVoicePath).exists() && java.io.File(effectiveCustomVoicePath).length() > 0) {
                effectiveVoiceMode = 1
            } else if (!isAppt && (isHydration || reminderId == "hyd" || isRoutine || reminderId.startsWith("act_") || reminderId.contains("act") || reminderId.contains("routine"))) {
                try {
                    val dataDir = context.applicationInfo.dataDir
                    val searchDirs = listOf(
                        java.io.File(dataDir, "app_flutter"),
                        java.io.File(dataDir, "files"),
                        context.filesDir
                    )
                    var latestFile: java.io.File? = null
                    for (dir in searchDirs) {
                        if (dir.exists() && dir.isDirectory) {
                            dir.listFiles()?.filter { f ->
                                f.isFile && (f.name.contains("hydration_voice_") || f.name.contains("custom_reminder_voice_") || f.name.contains("meal_voice_")) && f.name.endsWith(".m4a") && f.length() > 0
                            }?.forEach { f ->
                                if (latestFile == null || f.lastModified() > latestFile!!.lastModified()) {
                                    latestFile = f
                                }
                            }
                        }
                    }
                    if (latestFile != null && effectiveCustomVoicePath.isEmpty()) {
                        effectiveCustomVoicePath = latestFile!!.absolutePath
                        effectiveVoiceMode = 1
                        android.util.Log.d("AninaiTTS", "Auto-attached latest custom/hydration voice file for native alarm: $effectiveCustomVoicePath")
                    }
                } catch (e: Exception) {
                    android.util.Log.e("AninaiTTS", "Error finding latest custom voice file natively", e)
                }
            }

            // Check if user already completed this reminder
            if (reminderId.isNotEmpty()) {
                val compPrefs = context.getSharedPreferences("aninai_completed_reminders", Context.MODE_PRIVATE)
                if (compPrefs.getBoolean(reminderId, false)) {
                    android.util.Log.d("AninaiTTS", "Reminder $reminderId already completed. Skipping attempt $attemptCount")
                    return
                }
            }

            var displayTitle = title
            var displayBody = body
            var speechToDeliver = spokenText

            if (attemptCount == 2) {
                val tag = if (langCode == "ta") "(நினைவூட்டல் 2/3)" else "(Reminder 2/3)"
                displayTitle = "$title $tag"
            } else if (attemptCount == 3) {
                val tag = if (langCode == "ta") "(இறுதி எச்சரிக்கை 3/3)" else "(Final Alert 3/3)"
                displayTitle = "$title $tag"
            } else if (attemptCount >= 4) {
                displayTitle = "🚨 Caregiver Alert: Elder Missed Reminder!"
                displayBody = "Elder has not completed $title after 3 reminders. Please check on Elder."
                speechToDeliver = "Caregiver Alert! Elder has not completed $title after 3 reminders. Please check on Elder immediately."
            }

            // 1. Wake screen & acquire wake lock so alarm delivers even if screen is locked/off
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "Aninai:AlarmWakeLock"
            )
            wakeLock.acquire(15000)

            // 1b. Launch FullScreenAlarmActivity to arrest screen until an option button is selected (Suppressed for Hydration)
            if (attemptCount < 4 && !isHydration && reminderId != "hyd") {
                try {
                    val fullScreenIntent = Intent(context, FullScreenAlarmActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                        putExtra("notificationId", id)
                        putExtra("reminderId", reminderId)
                        putExtra("title", displayTitle)
                        putExtra("body", displayBody)
                        putExtra("takenLabel", takenLabel)
                        putExtra("yetToTakeLabel", yetToTakeLabel)
                        putExtra("isHydration", isHydration)
                        putExtra("langCode", langCode)
                        putExtra("medicineImagePath", medicineImagePath)
                        putExtra("pillsCount", pillsCount)
                    }
                    val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE else PendingIntent.FLAG_UPDATE_CURRENT
                    val fullScreenPendingIntent = PendingIntent.getActivity(context, id * 10 + 9, fullScreenIntent, piFlags)
                    try {
                        context.startActivity(fullScreenIntent)
                    } catch (e: Exception) {
                        fullScreenPendingIntent.send()
                    }
                } catch (e: Exception) {
                    android.util.Log.e("AninaiAlarm", "Error launching FullScreenAlarmActivity directly", e)
                }
            }

            // 2. Show High Priority System Notification Banner
            showSystemNotification(context, id, reminderId, displayTitle, displayBody, takenLabel, yetToTakeLabel, isHydration, showActions, langCode, medicineImagePath, pillsCount)

            // 3. For 4th Notification (Caregiver Alert), play Emergency Beep Alarm Sound instead of voice!
            if (attemptCount >= 4) {
                android.util.Log.d("AninaiTTS", "Attempt 4 Caregiver Alert: Playing Emergency Beep Alarm Sound")
                playEmergencyBeepAlarmSound(context.applicationContext, wakeLock)
            } else if (effectiveVoiceMode == 1 && effectiveCustomVoicePath.isNotEmpty() && java.io.File(effectiveCustomVoicePath).exists()) {
                android.util.Log.d("AninaiTTS", "Playing Option 1 custom recorded voice audio note directly: $effectiveCustomVoicePath")
                playCustomVoiceAudio(context.applicationContext, effectiveCustomVoicePath, wakeLock)
            } else {
                speakNativeNotificationText(context.applicationContext, speechToDeliver, fallbackText, langCode, id, displayTitle, displayBody, wakeLock, reminderId, isClonedVoice = (effectiveVoiceMode == 2))
            }

            // 4. If Hydration Reminder, automatically re-arm the next hourly alarm for 1 hour later
            if (isHydration || reminderId == "hyd") {
                val nextTriggerMs = System.currentTimeMillis() + (3600 * 1000L)
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
                val rearmIntent = Intent(context, AlarmReceiver::class.java).apply {
                    setAction("com.aninai.ACTION_TRIGGER_ALARM")
                    putExtra("id", 999999)
                    putExtra("title", title)
                    putExtra("body", body)
                    putExtra("reminderId", "hyd")
                    putExtra("takenLabel", takenLabel)
                    putExtra("yetToTakeLabel", yetToTakeLabel)
                    putExtra("spokenText", spokenText)
                    putExtra("fallbackText", fallbackText)
                    putExtra("customVoicePath", effectiveCustomVoicePath)
                    putExtra("voiceMode", effectiveVoiceMode)
                    putExtra("clonedVoiceSamplePath", "")
                    putExtra("langCode", langCode)
                    putExtra("isHydration", true)
                    putExtra("showActions", false)
                }
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    999999,
                    rearmIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                // Persist the re-armed hourly alarm timestamp in SharedPreferences so boot restore keeps it!
                try {
                    val prefs = context.getSharedPreferences("aninai_native_alarms", Context.MODE_PRIVATE)
                    val valueStr = "999999|||$nextTriggerMs|||$title|||$body|||hyd|||$takenLabel|||$yetToTakeLabel|||$spokenText|||$langCode|||true|||$effectiveCustomVoicePath|||$effectiveVoiceMode||||||$fallbackText|||false"
                    prefs.edit().putString("999999", valueStr).apply()
                } catch (e: Exception) {
                    android.util.Log.e("AninaiTTS", "Error updating native hydration alarm in SharedPreferences", e)
                }

                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        val alarmClockInfo = android.app.AlarmManager.AlarmClockInfo(nextTriggerMs, pendingIntent)
                        alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        alarmManager.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, nextTriggerMs, pendingIntent)
                    } else {
                        alarmManager.setExact(android.app.AlarmManager.RTC_WAKEUP, nextTriggerMs, pendingIntent)
                    }
                } catch (e: Exception) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        alarmManager.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, nextTriggerMs, pendingIntent)
                    } else {
                        alarmManager.setExact(android.app.AlarmManager.RTC_WAKEUP, nextTriggerMs, pendingIntent)
                    }
                }
            }
            // 5. If Medicine or Routine reminder and user has not completed it, schedule 1-minute retry alarm (Attempt 2, 3 & 4)
            else if (attemptCount < 4 && !isAppt && !isHydration && (showActions || isRoutine || reminderId.startsWith("med_") || reminderId.startsWith("act_") || reminderId.startsWith("temp_"))) {
                val nextAttempt = attemptCount + 1
                val baseId = (reminderId.hashCode().let { if (it < 0) -it else it }) % 100000
                val followUpAlarmId = baseId * 10 + nextAttempt

                val followUpIntent = Intent(context, AlarmReceiver::class.java).apply {
                    setAction("com.aninai.ACTION_TRIGGER_ALARM")
                    putExtra("id", followUpAlarmId)
                    putExtra("title", title)
                    putExtra("body", body)
                    putExtra("reminderId", reminderId)
                    putExtra("takenLabel", takenLabel)
                    putExtra("yetToTakeLabel", yetToTakeLabel)
                    putExtra("spokenText", spokenText)
                    putExtra("fallbackText", fallbackText)
                    putExtra("customVoicePath", customVoicePath)
                    putExtra("voiceMode", voiceMode)
                    putExtra("clonedVoiceSamplePath", clonedVoiceSamplePath)
                    putExtra("langCode", langCode)
                    putExtra("isHydration", false)
                    putExtra("showActions", showActions)
                    putExtra("attemptCount", nextAttempt)
                    putExtra("medicineImagePath", medicineImagePath)
                    putExtra("pillsCount", pillsCount)
                }

                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    followUpAlarmId,
                    followUpIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
                val triggerAtMs = System.currentTimeMillis() + 60000L // 1 Minute (60 seconds) later
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, triggerAtMs, pendingIntent)
                } else {
                    alarmManager.setExact(android.app.AlarmManager.RTC_WAKEUP, triggerAtMs, pendingIntent)
                }
            }
        }
    }

    private fun isAppointmentReminder(reminderId: String, title: String, body: String, spokenText: String = ""): Boolean {
        val idLower = reminderId.lowercase()
        val titleLower = title.lowercase()
        val bodyLower = body.lowercase()
        val spokenLower = spokenText.lowercase()
        return idLower.startsWith("apt_") || idLower.contains("apt") || idLower.contains("appointment") ||
                titleLower.contains("doctor") || titleLower.contains("appointment") || titleLower.contains("மருத்துவர்") || titleLower.contains("சந்திப்பு") || titleLower.contains("maruthuva") || titleLower.contains("sandhippu") ||
                bodyLower.contains("doctor") || bodyLower.contains("appointment") || bodyLower.contains("மருத்துவர்") || bodyLower.contains("சந்திப்பு") || bodyLower.contains("maruthuva") || bodyLower.contains("sandhippu") ||
                spokenLower.contains("maruthuva") || spokenLower.contains("sandhippu") || spokenLower.contains("doctor") || spokenLower.contains("appointment")
    }

    private fun speakNativeNotificationText(
        appContext: Context,
        rawText: String,
        fallbackText: String,
        langCode: String,
        id: Int,
        title: String,
        body: String,
        wakeLock: PowerManager.WakeLock,
        reminderId: String = "",
        isClonedVoice: Boolean = false
    ) {
        activeWakeLock = wakeLock

        try {
            activeTtsEngine?.stop()
            activeTtsEngine?.shutdown()
        } catch (_: Exception) {}

        activeTtsEngine = TextToSpeech(appContext) { status ->
            android.util.Log.d("AninaiTTS", "TTS initialization status: $status")
            try {
                if (status == TextToSpeech.SUCCESS && activeTtsEngine != null) {
                    android.util.Log.d("AninaiTTS", "TTS engine initialized successfully")
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        val audioAttrs = AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ASSISTANCE_ACCESSIBILITY)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                            .build()
                        activeTtsEngine?.setAudioAttributes(audioAttrs)
                    }

                    activeTtsEngine?.setPitch(0.98f)
                    activeTtsEngine?.setSpeechRate(0.85f)

                    // Automatically un-mute and boost media and alarm stream volumes so TTS is guaranteed audible!
                    try {
                        val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager
                        val maxMusic = audioManager.getStreamMaxVolume(android.media.AudioManager.STREAM_MUSIC)
                        val maxAlarm = audioManager.getStreamMaxVolume(android.media.AudioManager.STREAM_ALARM)
                        audioManager.setStreamVolume(android.media.AudioManager.STREAM_MUSIC, maxMusic, 0)
                        audioManager.setStreamVolume(android.media.AudioManager.STREAM_ALARM, maxAlarm, 0)
                    } catch (_: Exception) {}

                    val isTamil = langCode.equals("ta", ignoreCase = true)

                    if (isTamil) {
                        var tamilSet = false
                        try {
                            val avail = activeTtsEngine?.isLanguageAvailable(Locale("ta", "IN"))
                            if (avail == TextToSpeech.LANG_AVAILABLE || avail == TextToSpeech.LANG_COUNTRY_AVAILABLE || avail == TextToSpeech.LANG_COUNTRY_VAR_AVAILABLE) {
                                val setRes = activeTtsEngine?.setLanguage(Locale("ta", "IN"))
                                if (setRes != TextToSpeech.LANG_MISSING_DATA && setRes != TextToSpeech.LANG_NOT_SUPPORTED) {
                                    tamilSet = true
                                }
                            }
                        } catch (e: Exception) {
                            android.util.Log.e("AninaiTTS", "Error setting ta-IN locale", e)
                        }

                        if (!tamilSet) {
                            try {
                                activeTtsEngine?.setLanguage(Locale("en", "IN"))
                            } catch (_: Exception) {}
                        }
                    } else {
                        val loc = if (langCode.equals("as", ignoreCase = true) || langCode.equals("bn", ignoreCase = true)) {
                            Locale("bn", "IN")
                        } else {
                            Locale("en", "IN")
                        }
                        try {
                            activeTtsEngine?.setLanguage(loc)
                        } catch (_: Exception) {
                            try {
                                activeTtsEngine?.setLanguage(Locale.US)
                            } catch (_: Exception) {}
                        }
                    }

                    // Explicitly select Male AI Voice Engine (override default female voice)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        try {
                            val voices = activeTtsEngine?.voices
                            if (voices != null) {
                                val targetLang = langCode.lowercase()
                                var bestVoice: Voice? = null
                                for (v in voices) {
                                    val vName = v.name.lowercase()
                                    val vLang = v.locale.language.lowercase()
                                    if (vLang.contains(targetLang) || (targetLang == "ta" && vName.contains("ta-in"))) {
                                        if (vName.contains("-tac-") || vName.contains("male") || vName.contains("-tam-") || vName.contains("boy")) {
                                            bestVoice = v
                                            break
                                        } else if (!vName.contains("female") && !vName.contains("-taf-")) {
                                            bestVoice = v
                                        }
                                    }
                                }
                                if (bestVoice != null) {
                                    activeTtsEngine?.voice = bestVoice
                                    android.util.Log.d("AninaiTTS", "Selected Native Male Voice: ${bestVoice.name}")
                                }
                            }
                        } catch (e: Exception) {
                            android.util.Log.e("AninaiTTS", "Error selecting male voice in AlarmReceiver", e)
                        }
                    }

                    val cleanRaw = rawText
                        .replace(Regex("[^\\p{L}\\p{N}\\p{P}\\p{Z}]"), "")
                        .replace(Regex("pill\\(s\\)", RegexOption.IGNORE_CASE), "pill")
                        .replace(Regex("\\(s\\)", RegexOption.IGNORE_CASE), "")
                        .replace("•", ",")
                        .replace(Regex("\\s+"), " ")
                        .trim()

                    val cleanTitle = title
                        .replace(Regex("[^\\p{L}\\p{N}\\p{P}\\p{Z}]"), "")
                        .replace(Regex("\\s+"), " ")
                        .trim()

                    val cleanBody = body
                        .replace(Regex("[^\\p{L}\\p{N}\\p{P}\\p{Z}]"), "")
                        .replace(Regex("pill\\(s\\)", RegexOption.IGNORE_CASE), "pill")
                        .replace(Regex("\\(s\\)", RegexOption.IGNORE_CASE), "")
                        .replace("•", ",")
                        .replace(Regex("\\s+"), " ")
                        .trim()

                    val cleanFallbackText = fallbackText
                        .replace(Regex("[^\\p{L}\\p{N}\\p{P}\\p{Z}]"), "")
                        .replace(Regex("pill\\(s\\)", RegexOption.IGNORE_CASE), "pill")
                        .replace(Regex("\\(s\\)", RegexOption.IGNORE_CASE), "")
                        .replace("•", ",")
                        .replace(Regex("\\s+"), " ")
                        .trim()

                    val isApptNotification = isAppointmentReminder(reminderId, title, body, rawText)

                    val textToSpeak = if (isApptNotification) {
                        if (isTamil) {
                            if (activeTtsEngine?.language?.language == "ta") {
                                if (cleanRaw.isNotEmpty()) cleanRaw else "மருத்துவ சந்திப்பு நேரம். $cleanTitle மருத்துவரைச் சந்திக்க வேண்டும்."
                            } else {
                                if (cleanFallbackText.isNotEmpty()) cleanFallbackText else if (cleanRaw.isNotEmpty()) cleanRaw else "Maruthuva sandhippu neram. $cleanTitle maruthuvarai sandhikka veendum."
                            }
                        } else {
                            if (cleanRaw.isNotEmpty()) cleanRaw else "Doctor appointment reminder. Time for appointment with $cleanTitle."
                        }
                    } else if (isTamil) {
                        if (activeTtsEngine?.language?.language == "ta") {
                            if (cleanRaw.isNotEmpty()) cleanRaw else "$cleanTitle. $cleanBody"
                        } else {
                            // Phonetic Tamil for Indian English TTS (en-IN)
                            if (cleanFallbackText.isNotEmpty()) {
                                cleanFallbackText
                            } else {
                                var phoneticFromRaw = cleanRaw
                                    .replace("மருத்துவ சந்திப்பு நேரம்", "Maruthuva sandhippu neram")
                                    .replace("மருத்துவரைச் சந்திக்க வேண்டும்", "maruthuvarai sandhikka veendum")
                                    .replace("தினசரி நடவடிக்கை நினைவூட்டல்", "Dinasari nadavadikkai ninaivootal")
                                    .replace("செய்ய வேண்டும்", "seyya veendum")
                                    .replace("மணிக்கு", "manikku")
                                    .replace("மருந்து அருந்தும் நேரம்", "Marunthu arunthum neram")
                                    .replace("காலை உணவுக்கு முன்", "Kaalai unavukku mun")
                                    .replace("காலை உணவுக்குப் பின்", "Kaalai unavukku pin")
                                    .replace("காலை உணவுக்கு பின்", "Kaalai unavukku pin")
                                    .replace("மதிய உணவுக்கு முன்", "Mathiya unavukku mun")
                                    .replace("மதிய உணவுக்குப் பின்", "Mathiya unavukku pin")
                                    .replace("மதிய உணவுக்கு பின்", "Mathiya unavukku pin")
                                    .replace("இரவு உணவுக்கு முன்", "Iravu unavukku mun")
                                    .replace("இரவு உணவுக்குப் பின்", "Iravu unavukku pin")
                                    .replace("இரவு உணவுக்கு பின்", "Iravu unavukku pin")
                                    .replace("இரவு தூங்குவதற்கு முன்", "Iravu thookathirku mun")
                                    .replace("இரவு தூக்கத்திற்கு முன்", "Iravu thookathirku mun")
                                    .replace("முழு டம்ளர் தண்ணீருடன்", "Mulu tumbler thanneerudan")
                                    .replace("உணவுக்குப் பின்", "Unavukku pin")
                                    .replace("உணவுக்கு பின்", "Unavukku pin")
                                    .replace("உணவுக்கு முன்", "Unavukku mun")
                                    .replace("மாத்திரைகள் எடுக்கவும்", "maathiraigal edukavum")
                                    .replace("மாத்திரை சாப்பிடவும்", "maathiraigal edukavum")
                                    .replace("மாத்திரை", "maathirai")
                                    .replace(Regex("[^\\x00-\\x7F]"), "")
                                    .replace(Regex("\\s+"), " ")
                                    .trim()

                                if (phoneticFromRaw.isNotEmpty()) {
                                    phoneticFromRaw
                                } else {
                                    "Reminder notification for $cleanTitle."
                                }
                            }
                        }
                    } else {
                        // English Mode
                        if (cleanRaw.isNotEmpty()) {
                            cleanRaw
                        } else if (cleanTitle.isNotEmpty()) {
                            "$cleanTitle. $cleanBody"
                        } else {
                            "Reminder notification. Time for your scheduled activity."
                        }
                    }

                    activeTtsEngine?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                        override fun onStart(utteranceId: String?) {}
                        override fun onDone(utteranceId: String?) {
                            cleanupTts()
                        }
                        override fun onError(utteranceId: String?) {
                            cleanupTts()
                        }
                    })

                    android.util.Log.d("AninaiTTS", "Speaking text: $textToSpeak")
                    activeTtsEngine?.speak(textToSpeak, TextToSpeech.QUEUE_FLUSH, null, "AlarmTTS_$id")
                } else {
                    android.util.Log.e("AninaiTTS", "TTS initialization failed with status: $status")
                    cleanupTts()
                }
            } catch (e: Exception) {
                android.util.Log.e("AninaiTTS", "TTS initialization exception", e)
                cleanupTts()
            }
        }
    }

    private fun playCustomVoiceAudio(appContext: Context, voicePath: String, wakeLock: PowerManager.WakeLock) {
        activeWakeLock = wakeLock
        try {
            try {
                val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager
                val maxMusic = audioManager.getStreamMaxVolume(android.media.AudioManager.STREAM_MUSIC)
                val maxAlarm = audioManager.getStreamMaxVolume(android.media.AudioManager.STREAM_ALARM)
                audioManager.setStreamVolume(android.media.AudioManager.STREAM_MUSIC, maxMusic, 0)
                audioManager.setStreamVolume(android.media.AudioManager.STREAM_ALARM, maxAlarm, 0)
            } catch (_: Exception) {}

            val mp = android.media.MediaPlayer()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                mp.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ASSISTANCE_ACCESSIBILITY)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
            }
            mp.setDataSource(voicePath)
            mp.prepare()
            mp.setOnCompletionListener { mediaPlayer ->
                try { mediaPlayer.release() } catch (_: Exception) {}
                try {
                    if (activeWakeLock?.isHeld == true) {
                        activeWakeLock?.release()
                        activeWakeLock = null
                    }
                } catch (_: Exception) {}
            }
            mp.setOnErrorListener { mediaPlayer, _, _ ->
                try { mediaPlayer.release() } catch (_: Exception) {}
                try {
                    if (activeWakeLock?.isHeld == true) {
                        activeWakeLock?.release()
                        activeWakeLock = null
                    }
                } catch (_: Exception) {}
                true
            }
            mp.start()
            android.util.Log.d("AninaiTTS", "Playing custom recorded voice audio: $voicePath")
        } catch (e: Exception) {
            android.util.Log.e("AninaiTTS", "Error playing custom recorded voice audio note", e)
            try {
                if (activeWakeLock?.isHeld == true) {
                    activeWakeLock?.release()
                    activeWakeLock = null
                }
            } catch (_: Exception) {}
        }
    }

    private fun playCustomVoiceAudioThenSpeakTts(
        appContext: Context,
        voicePath: String,
        spokenText: String,
        fallbackText: String,
        langCode: String,
        id: Int,
        title: String,
        body: String,
        wakeLock: PowerManager.WakeLock,
        reminderId: String = ""
    ) {
        activeWakeLock = wakeLock
        try {
            try {
                val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager
                val maxMusic = audioManager.getStreamMaxVolume(android.media.AudioManager.STREAM_MUSIC)
                val maxAlarm = audioManager.getStreamMaxVolume(android.media.AudioManager.STREAM_ALARM)
                audioManager.setStreamVolume(android.media.AudioManager.STREAM_MUSIC, maxMusic, 0)
                audioManager.setStreamVolume(android.media.AudioManager.STREAM_ALARM, maxAlarm, 0)
            } catch (_: Exception) {}

            val mp = android.media.MediaPlayer()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                mp.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ASSISTANCE_ACCESSIBILITY)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
            }
            mp.setDataSource(voicePath)
            mp.prepare()
            mp.setOnCompletionListener { mediaPlayer ->
                try { mediaPlayer.release() } catch (_: Exception) {}
                speakNativeNotificationText(appContext, spokenText, fallbackText, langCode, id, title, body, wakeLock, reminderId, isClonedVoice = true)
            }
            mp.setOnErrorListener { mediaPlayer, _, _ ->
                try { mediaPlayer.release() } catch (_: Exception) {}
                speakNativeNotificationText(appContext, spokenText, fallbackText, langCode, id, title, body, wakeLock, reminderId, isClonedVoice = true)
                true
            }
            mp.start()
            android.util.Log.d("AninaiTTS", "Playing grandson voice intro clip: $voicePath")
        } catch (e: Exception) {
            android.util.Log.e("AninaiTTS", "Error playing grandson voice intro clip", e)
            speakNativeNotificationText(appContext, spokenText, fallbackText, langCode, id, title, body, wakeLock, reminderId, isClonedVoice = true)
        }
    }

    private fun cleanupTts() {
        try {
            activeTtsEngine?.stop()
            activeTtsEngine?.shutdown()
            activeTtsEngine = null
        } catch (_: Exception) {}
        try {
            if (activeWakeLock?.isHeld == true) {
                activeWakeLock?.release()
                activeWakeLock = null
            }
        } catch (_: Exception) {}
    }

    private fun restoreAlarmsOnBoot(context: Context) {
        try {
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val userJson = flutterPrefs.getString("flutter.aninai_user", "") ?: ""
            if (userJson.contains("\"role\":\"caretaker\"") || userJson.contains("\"role\": \"caretaker\"")) {
                android.util.Log.d("AninaiTTS", "User is Caregiver on boot. Skipping alarm restoration.")
                return
            }

            val prefs = context.getSharedPreferences("aninai_native_alarms", Context.MODE_PRIVATE)
            val all = prefs.all
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager

            for ((_, value) in all) {
                if (value is String) {
                    val parts = value.split("|||")
                    if (parts.size >= 9) {
                        val id = parts[0].toIntOrNull() ?: continue
                        val triggerAtMs = parts[1].toLongOrNull() ?: continue
                        val title = parts[2]
                        val body = parts[3]
                        val reminderId = parts[4]
                        val takenLabel = parts[5]
                        val yetToTakeLabel = parts[6]
                        val spokenText = parts[7]
                        val langCode = parts[8]
                        val isHydration = parts.getOrNull(9)?.toBoolean() ?: false
                        val customVoicePath = parts.getOrNull(10) ?: ""
                        val voiceMode = parts.getOrNull(11)?.toIntOrNull() ?: 0
                        val clonedVoiceSamplePath = parts.getOrNull(12) ?: ""

                        val fallbackText = parts.getOrNull(13) ?: ""
                        val showActions = parts.getOrNull(14)?.toBoolean() ?: (!isAppointmentReminder(reminderId, title, body))
                        val medicineImagePath = parts.getOrNull(15) ?: ""
                        val pillsCount = parts.getOrNull(16) ?: ""

                        if (triggerAtMs > System.currentTimeMillis()) {
                            val alarmIntent = Intent(context, AlarmReceiver::class.java).apply {
                                setAction("com.aninai.ACTION_TRIGGER_ALARM")
                                putExtra("id", id)
                                putExtra("title", title)
                                putExtra("body", body)
                                putExtra("reminderId", reminderId)
                                putExtra("takenLabel", takenLabel)
                                putExtra("yetToTakeLabel", yetToTakeLabel)
                                putExtra("spokenText", spokenText)
                                putExtra("fallbackText", fallbackText)
                                putExtra("customVoicePath", customVoicePath)
                                putExtra("voiceMode", voiceMode)
                                putExtra("clonedVoiceSamplePath", clonedVoiceSamplePath)
                                putExtra("langCode", langCode)
                                putExtra("isHydration", isHydration)
                                putExtra("showActions", showActions)
                                putExtra("medicineImagePath", medicineImagePath)
                                putExtra("pillsCount", pillsCount)
                            }
                            val pendingIntent = PendingIntent.getBroadcast(
                                context,
                                id,
                                alarmIntent,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                            )

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
                    }
                }
            }
        } catch (_: Exception) {}
    }

    private fun showSystemNotification(
        context: Context,
        id: Int,
        reminderId: String,
        title: String,
        body: String,
        takenLabel: String,
        yetToTakeLabel: String,
        isHydration: Boolean,
        showActions: Boolean = true,
        langCode: String = "en",
        medicineImagePath: String = "",
        pillsCount: String = ""
    ) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
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

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val activityFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(context, id, launchIntent, activityFlags)

        val fullScreenIntent = Intent(context, FullScreenAlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtra("notificationId", id)
            putExtra("reminderId", reminderId)
            putExtra("title", title)
            putExtra("body", body)
            putExtra("takenLabel", takenLabel)
            putExtra("yetToTakeLabel", yetToTakeLabel)
            putExtra("isHydration", isHydration)
            putExtra("langCode", langCode)
            putExtra("medicineImagePath", medicineImagePath)
            putExtra("pillsCount", pillsCount)
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(context, id * 10 + 9, fullScreenIntent, activityFlags)

        val broadcastFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val takenIntent = Intent(context, NotificationActionReceiver::class.java).apply {
            setAction("com.aninai.ACTION_TAKEN")
            putExtra("reminderId", reminderId)
            putExtra("notificationId", id)
        }
        val takenPendingIntent = PendingIntent.getBroadcast(context, id * 10 + 1, takenIntent, broadcastFlags)

        val yetToTakeIntent = Intent(context, NotificationActionReceiver::class.java).apply {
            setAction("com.aninai.ACTION_YET_TO_TAKE")
            putExtra("reminderId", reminderId)
            putExtra("notificationId", id)
        }
        val yetToTakePendingIntent = PendingIntent.getBroadcast(context, id * 10 + 2, yetToTakeIntent, broadcastFlags)

        var iconRes = context.applicationInfo.icon
        if (iconRes == 0) {
            iconRes = R.mipmap.ic_launcher
        }

        val builder = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(iconRes)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setVibrate(longArrayOf(0, 500, 250, 500))
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)

        if (!isHydration && reminderId != "hyd") {
            builder.setFullScreenIntent(fullScreenPendingIntent, true)
        }

        val isAppointment = isAppointmentReminder(reminderId, title, body)
        if (isHydration) {
            val logWaterIntent = Intent(context, NotificationActionReceiver::class.java).apply {
                action = "com.aninai.ACTION_LOG_WATER"
                putExtra("reminderId", if (reminderId.isNotEmpty()) reminderId else "hyd")
                putExtra("notificationId", id)
                putExtra("isHydration", true)
            }
            val logWaterPendingIntent = PendingIntent.getBroadcast(context, id * 10 + 3, logWaterIntent, broadcastFlags)
            val logBtnText = if (takenLabel.isNotEmpty() && takenLabel != "Taken") takenLabel else "💧 Log 1 Glass Water"
            val actionLogWater = NotificationCompat.Action.Builder(0, logBtnText, logWaterPendingIntent).build()
            builder.addAction(actionLogWater)
        } else if (showActions && !isAppointment) {
            val actionTaken = NotificationCompat.Action.Builder(0, "✅ $takenLabel", takenPendingIntent).build()
            val actionYetToTake = NotificationCompat.Action.Builder(0, "⏳ $yetToTakeLabel", yetToTakePendingIntent).build()
            builder.addAction(actionTaken)
            builder.addAction(actionYetToTake)
        }

        notificationManager.notify(id, builder.build())
    }

    private fun playEmergencyBeepAlarmSound(appContext: Context, wakeLock: PowerManager.WakeLock) {
        activeWakeLock = wakeLock
        try {
            val audioManager = appContext.getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager
            val maxAlarm = audioManager.getStreamMaxVolume(android.media.AudioManager.STREAM_ALARM)
            audioManager.setStreamVolume(android.media.AudioManager.STREAM_ALARM, maxAlarm, 0)

            var alarmUri = android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_ALARM)
            if (alarmUri == null) {
                alarmUri = android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION)
            }
            if (alarmUri == null) {
                alarmUri = android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_RINGTONE)
            }

            val ringtone = android.media.RingtoneManager.getRingtone(appContext, alarmUri)
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
                    android.util.Log.e("AninaiTTS", "Error generating emergency beeps", e)
                }
            }.start()

            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                try { ringtone?.stop() } catch (_: Exception) {}
                try {
                    if (activeWakeLock?.isHeld == true) {
                        activeWakeLock?.release()
                        activeWakeLock = null
                    }
                } catch (_: Exception) {}
            }, 10000)

            android.util.Log.d("AninaiTTS", "Played Emergency Beep Alarm Sound for Attempt 4 Caregiver Alert")
        } catch (e: Exception) {
            android.util.Log.e("AninaiTTS", "Error playing emergency beep alarm sound", e)
            try {
                if (activeWakeLock?.isHeld == true) {
                    activeWakeLock?.release()
                    activeWakeLock = null
                }
            } catch (_: Exception) {}
        }
    }
}
